"""Access to the AI model (Gemma 4 through the Gemini API).

The network call is hidden behind a small transport interface, so the logic
(model fallback, safety blocks, answer extraction) can be tested without
internet and without a real key.
"""

from __future__ import annotations

import base64
import logging
import time
from abc import ABC, abstractmethod
from collections.abc import Callable
from dataclasses import dataclass
from enum import Enum
from typing import Protocol

from .config import Settings
from .prompts import SYSTEM_INSTRUCTION

_BLOCKING_FINISH_REASONS = ("SAFETY", "PROHIBITED_CONTENT", "BLOCKLIST", "SPII", "RECITATION")

# The mobile app gives up after 40 seconds. The server must answer before that,
# even when it has to try two models one after the other.
_TOTAL_DEADLINE_SECONDS = 36.0

# A new attempt with less time than this would only fail by timeout.
_MINIMUM_SECONDS_FOR_ANOTHER_ATTEMPT = 5.0

_LOGGER = logging.getLogger("radar.backend")


class AiProviderErrorKind(str, Enum):
    NOT_CONFIGURED = "not_configured"
    RATE_LIMITED = "rate_limited"
    UNAVAILABLE = "unavailable"
    BLOCKED = "blocked"
    INVALID_RESPONSE = "invalid_response"


class AiProviderError(Exception):
    def __init__(self, kind: AiProviderErrorKind, message: str) -> None:
        super().__init__(message)
        self.kind = kind
        self.message = message


@dataclass(frozen=True)
class ImagePayload:
    image_bytes: bytes
    mime_type: str


@dataclass(frozen=True)
class ProviderOutput:
    raw_text: str
    model_name: str
    total_token_count: int | None


class AiProvider(ABC):
    @abstractmethod
    async def generate_verdict(self, *, user_prompt: str, image: ImagePayload | None) -> ProviderOutput:
        """Ask the model for a verdict and return its raw text answer."""


class HttpTransportError(Exception):
    """The network call failed (no connection, timeout, ...)."""


@dataclass(frozen=True)
class HttpJsonResponse:
    status_code: int
    body: dict | None


class HttpJsonTransport(Protocol):
    async def post_json(
        self, *, url: str, headers: dict[str, str], payload: dict, timeout_seconds: float
    ) -> HttpJsonResponse: ...


class HttpxJsonTransport:
    """Real network transport. The httpx library is imported only here."""

    def __init__(self) -> None:
        import httpx

        self._httpx = httpx
        self._client = httpx.AsyncClient()

    async def post_json(
        self, *, url: str, headers: dict[str, str], payload: dict, timeout_seconds: float
    ) -> HttpJsonResponse:
        try:
            response = await self._client.post(url, headers=headers, json=payload, timeout=timeout_seconds)
        except self._httpx.HTTPError as error:
            # The original error is not forwarded: it may contain the request URL.
            raise HttpTransportError("Network call failed.") from error

        try:
            parsed_body = response.json()
        except ValueError:
            parsed_body = None

        return HttpJsonResponse(
            status_code=response.status_code,
            body=parsed_body if isinstance(parsed_body, dict) else None,
        )

    async def close(self) -> None:
        await self._client.aclose()


class GemmaGeminiProvider(AiProvider):
    def __init__(
        self,
        *,
        settings: Settings,
        transport: HttpJsonTransport,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._settings = settings
        self._transport = transport
        # The clock can be replaced in tests, so the time budget can be checked without waiting.
        self._clock = clock

    async def generate_verdict(self, *, user_prompt: str, image: ImagePayload | None) -> ProviderOutput:
        if not self._settings.is_ai_configured:
            raise AiProviderError(AiProviderErrorKind.NOT_CONFIGURED, "No AI key is configured.")

        model_names = [self._settings.primary_model_name]

        if self._settings.fallback_model_name and self._settings.fallback_model_name != self._settings.primary_model_name:
            model_names.append(self._settings.fallback_model_name)

        last_recoverable_error: AiProviderError | None = None
        started_at = self._clock()

        for model_name in model_names:
            seconds_left = _TOTAL_DEADLINE_SECONDS - (self._clock() - started_at)

            # Guard clause: do not start a second attempt that cannot finish in time.
            if last_recoverable_error is not None and seconds_left < _MINIMUM_SECONDS_FOR_ANOTHER_ATTEMPT:
                break

            timeout_seconds = min(self._settings.request_timeout_seconds, seconds_left)

            try:
                return await self._call_model(model_name, user_prompt, image, timeout_seconds)
            except AiProviderError as error:
                # Another model has its own quota, so it can help for these two cases only.
                if error.kind not in (AiProviderErrorKind.RATE_LIMITED, AiProviderErrorKind.UNAVAILABLE):
                    raise

                last_recoverable_error = error

        assert last_recoverable_error is not None
        raise last_recoverable_error

    def _build_payload(self, user_prompt: str, image: ImagePayload | None) -> dict:
        parts: list[dict] = []

        if image is not None:
            # The image is sent inside the request (not uploaded as a stored file),
            # so nothing stays on the provider side as a file.
            parts.append(
                {
                    "inline_data": {
                        "mime_type": image.mime_type,
                        "data": base64.b64encode(image.image_bytes).decode("ascii"),
                    }
                }
            )

        parts.append({"text": user_prompt})

        generation_config: dict = {
            "temperature": 0.2,
            "maxOutputTokens": self._settings.maximum_output_tokens,
        }

        if self._settings.thinking_level:
            generation_config["thinkingConfig"] = {"thinkingLevel": self._settings.thinking_level}

        return {
            "systemInstruction": {"parts": [{"text": SYSTEM_INSTRUCTION}]},
            "contents": [{"role": "user", "parts": parts}],
            "generationConfig": generation_config,
        }

    async def _call_model(
        self, model_name: str, user_prompt: str, image: ImagePayload | None, timeout_seconds: float
    ) -> ProviderOutput:
        url = f"{self._settings.api_base_url}/models/{model_name}:generateContent"
        headers = {
            "x-goog-api-key": self._settings.gemini_api_key,
            "Content-Type": "application/json",
        }
        call_started_at = self._clock()
        status_code: int | str = "no_response"

        try:
            try:
                response = await self._transport.post_json(
                    url=url,
                    headers=headers,
                    payload=self._build_payload(user_prompt, image),
                    timeout_seconds=timeout_seconds,
                )
            except HttpTransportError as error:
                raise AiProviderError(AiProviderErrorKind.UNAVAILABLE, "The AI service cannot be reached.") from error

            status_code = response.status_code
            self._raise_for_status(response.status_code)

            if response.body is None:
                raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI service sent an unreadable answer.")

            return self._extract_output(response.body, model_name)
        except AiProviderError as error:
            # Only technical facts are logged. The message or image content is never logged.
            _LOGGER.warning(
                "ai_call_failed model=%s kind=%s status=%s timeout_s=%.0f elapsed_ms=%d image_bytes=%s",
                model_name,
                error.kind.value,
                status_code,
                timeout_seconds,
                int((self._clock() - call_started_at) * 1000),
                len(image.image_bytes) if image is not None else 0,
            )
            raise

    @staticmethod
    def _raise_for_status(status_code: int) -> None:
        if status_code == 200:
            return

        if status_code == 429:
            raise AiProviderError(AiProviderErrorKind.RATE_LIMITED, "The AI quota is exhausted for now.")

        if status_code in (401, 403):
            raise AiProviderError(AiProviderErrorKind.NOT_CONFIGURED, "The AI key was refused.")

        if status_code == 400:
            raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI service refused the request.")

        # 404 (unknown model), 5xx and anything else: the other model may work.
        raise AiProviderError(AiProviderErrorKind.UNAVAILABLE, "The AI service is not available.")

    @staticmethod
    def _extract_output(body: dict, model_name: str) -> ProviderOutput:
        candidates = body.get("candidates")

        if not isinstance(candidates, list) or not candidates:
            prompt_feedback = body.get("promptFeedback")

            if isinstance(prompt_feedback, dict) and prompt_feedback.get("blockReason"):
                raise AiProviderError(AiProviderErrorKind.BLOCKED, "The content was blocked by the AI safety filter.")

            raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI service sent no answer.")

        first_candidate = candidates[0]

        if not isinstance(first_candidate, dict):
            raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI answer has an unexpected shape.")

        if first_candidate.get("finishReason") in _BLOCKING_FINISH_REASONS:
            raise AiProviderError(AiProviderErrorKind.BLOCKED, "The answer was blocked by the AI safety filter.")

        content = first_candidate.get("content")
        parts = content.get("parts") if isinstance(content, dict) else None

        if not isinstance(parts, list):
            raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI answer has no content.")

        # "Thinking" parts are internal notes of the model: they are not the answer.
        answer_texts = [
            part["text"]
            for part in parts
            if isinstance(part, dict) and isinstance(part.get("text"), str) and not part.get("thought")
        ]

        if not answer_texts:
            raise AiProviderError(AiProviderErrorKind.INVALID_RESPONSE, "The AI answer has no text.")

        usage_metadata = body.get("usageMetadata")
        total_token_count = usage_metadata.get("totalTokenCount") if isinstance(usage_metadata, dict) else None

        return ProviderOutput(
            raw_text="".join(answer_texts),
            model_name=model_name,
            total_token_count=total_token_count if isinstance(total_token_count, int) else None,
        )
