"""Business logic of the backend: validate, protect the quota, ask the model, check the answer.

Privacy rule: this module never writes the content of a message to a log.
Only counters and technical facts are logged.
"""

from __future__ import annotations

import logging
import time
from dataclasses import dataclass

from .ai_provider import AiProvider, AiProviderError, AiProviderErrorKind, ImagePayload, ProviderOutput
from .cache import ExpiringCache, compute_text_cache_key
from .config import Settings
from .input_validation import sanitize_text, validate_image
from .prompts import build_image_prompt, build_text_prompt
from .rate_limiter import SlidingWindowRateLimiter
from .verdict_parser import AiSignal, VerdictParsingError, parse_ai_verdict

LEVEL_SUSPICIOUS_THRESHOLD = 20
LEVEL_DANGEROUS_THRESHOLD = 45

_GLOBAL_RATE_LIMIT_KEY = "global"


class AnalysisServiceError(Exception):
    def __init__(self, code: str, message: str, http_status: int, retry_after_seconds: int | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = http_status
        self.retry_after_seconds = retry_after_seconds


@dataclass(frozen=True)
class AnalysisResult:
    risk_score: int
    level: str
    threat_family: str | None
    signals: tuple[AiSignal, ...]
    recommended_actions: tuple[str, ...]
    extracted_text: str | None
    model_name: str

    def to_response_dict(self) -> dict:
        return {
            "level": self.level,
            "riskScore": self.risk_score,
            "threatFamily": self.threat_family,
            "signals": [{"title": signal.title, "explanation": signal.explanation} for signal in self.signals],
            "recommendedActions": list(self.recommended_actions),
            "extractedText": self.extracted_text,
            "modelName": self.model_name,
            "source": "ai",
        }


def determine_level(risk_score: int) -> str:
    # The level always comes from the score, never from the model words.
    # There is no "safe" level on purpose.
    if risk_score >= LEVEL_DANGEROUS_THRESHOLD:
        return "dangerous"

    if risk_score >= LEVEL_SUSPICIOUS_THRESHOLD:
        return "suspicious"

    return "noSignalFound"


class AnalysisService:
    def __init__(
        self,
        *,
        settings: Settings,
        provider: AiProvider,
        cache: ExpiringCache[AnalysisResult],
        client_rate_limiter: SlidingWindowRateLimiter,
        global_rate_limiter: SlidingWindowRateLimiter,
        logger: logging.Logger | None = None,
    ) -> None:
        self._settings = settings
        self._provider = provider
        self._cache = cache
        self._client_rate_limiter = client_rate_limiter
        self._global_rate_limiter = global_rate_limiter
        self._logger = logger or logging.getLogger("radar.backend")

    async def analyze_text(self, *, raw_text: object, client_identifier: str) -> AnalysisResult:
        started_at = time.monotonic()
        cleaned_text = sanitize_text(raw_text, self._settings.maximum_text_characters)

        self._require_ai_configured()
        self._enforce_client_limit(client_identifier)

        cache_key = compute_text_cache_key(cleaned_text)
        cached_result = self._cache.get(cache_key)

        if cached_result is not None:
            self._log_completion("text", cached_result, None, True, started_at)
            return cached_result

        self._enforce_global_limit()

        text_for_model = cleaned_text[: self._settings.maximum_ai_input_characters]
        provider_output = await self._ask_provider(build_text_prompt(text_for_model), None)
        result = self._build_result(provider_output, include_extracted_text=False)

        self._cache.put(cache_key, result)
        self._log_completion("text", result, provider_output.total_token_count, False, started_at)
        return result

    async def analyze_image(self, *, image_bytes: bytes, client_identifier: str) -> AnalysisResult:
        started_at = time.monotonic()
        mime_type = validate_image(image_bytes, self._settings.maximum_image_bytes)

        self._require_ai_configured()
        self._enforce_client_limit(client_identifier)
        self._enforce_global_limit()

        provider_output = await self._ask_provider(
            build_image_prompt(), ImagePayload(image_bytes=image_bytes, mime_type=mime_type)
        )
        result = self._build_result(provider_output, include_extracted_text=True)

        self._log_completion("image", result, provider_output.total_token_count, False, started_at)
        return result

    def _require_ai_configured(self) -> None:
        if not self._settings.is_ai_configured:
            raise AnalysisServiceError("ai_not_configured", "The AI service is not configured on the server.", 503)

    def _enforce_client_limit(self, client_identifier: str) -> None:
        if self._client_rate_limiter.try_acquire(client_identifier):
            return

        raise AnalysisServiceError(
            "rate_limited",
            "Too many requests. Please wait a moment.",
            429,
            retry_after_seconds=self._client_rate_limiter.seconds_until_available(client_identifier),
        )

    def _enforce_global_limit(self) -> None:
        if self._global_rate_limiter.try_acquire(_GLOBAL_RATE_LIMIT_KEY):
            return

        raise AnalysisServiceError(
            "ai_busy",
            "The AI service is very busy. Please retry shortly.",
            429,
            retry_after_seconds=self._global_rate_limiter.seconds_until_available(_GLOBAL_RATE_LIMIT_KEY),
        )

    async def _ask_provider(self, user_prompt: str, image: ImagePayload | None) -> ProviderOutput:
        try:
            return await self._provider.generate_verdict(user_prompt=user_prompt, image=image)
        except AiProviderError as error:
            raise self._convert_provider_error(error) from error

    @staticmethod
    def _convert_provider_error(error: AiProviderError) -> AnalysisServiceError:
        if error.kind == AiProviderErrorKind.RATE_LIMITED:
            return AnalysisServiceError("ai_rate_limited", "The AI quota is exhausted for now.", 429, retry_after_seconds=30)

        if error.kind == AiProviderErrorKind.BLOCKED:
            return AnalysisServiceError("content_blocked", "The AI service could not process this content.", 422)

        if error.kind == AiProviderErrorKind.NOT_CONFIGURED:
            return AnalysisServiceError("ai_not_configured", "The AI service is not configured on the server.", 503)

        if error.kind == AiProviderErrorKind.INVALID_RESPONSE:
            return AnalysisServiceError("ai_invalid_response", "The AI service sent an unusable answer.", 502)

        return AnalysisServiceError("ai_unavailable", "The AI service is not available.", 503)

    @staticmethod
    def _build_result(provider_output: ProviderOutput, *, include_extracted_text: bool) -> AnalysisResult:
        try:
            verdict = parse_ai_verdict(provider_output.raw_text)
        except VerdictParsingError as error:
            raise AnalysisServiceError("ai_invalid_response", "The AI service sent an unusable answer.", 502) from error

        return AnalysisResult(
            risk_score=verdict.risk_score,
            level=determine_level(verdict.risk_score),
            threat_family=verdict.threat_family,
            signals=verdict.signals,
            recommended_actions=verdict.recommended_actions,
            extracted_text=verdict.extracted_text if include_extracted_text else None,
            model_name=provider_output.model_name,
        )

    def _log_completion(
        self,
        analysis_kind: str,
        result: AnalysisResult,
        total_token_count: int | None,
        was_cached: bool,
        started_at: float,
    ) -> None:
        latency_milliseconds = int((time.monotonic() - started_at) * 1000)

        # Only technical facts are logged. The message content is never logged.
        self._logger.info(
            "analysis kind=%s level=%s tokens=%s cached=%s model=%s latency_ms=%d",
            analysis_kind,
            result.level,
            total_token_count,
            was_cached,
            result.model_name,
            latency_milliseconds,
        )
