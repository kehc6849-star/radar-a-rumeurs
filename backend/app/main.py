"""HTTP entry point of the Zero Trust backend."""

import hmac
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, Header, Request, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from .ai_provider import AiProvider, GemmaGeminiProvider, HttpxJsonTransport
from .analysis_service import AnalysisResult, AnalysisService, AnalysisServiceError
from .cache import ExpiringCache
from .config import Settings, load_environment_file
from .input_validation import InputValidationError
from .rate_limiter import SlidingWindowRateLimiter

_LOGGER = logging.getLogger("radar.backend")


class AnalyzeTextRequest(BaseModel):
    text: str


def _build_error_response(
    code: str, message: str, http_status: int, retry_after_seconds: int | None = None
) -> JSONResponse:
    headers = {"Retry-After": str(retry_after_seconds)} if retry_after_seconds else None
    return JSONResponse(
        status_code=http_status,
        content={"error": {"code": code, "message": message}},
        headers=headers,
    )


def _verify_access_token(settings: Settings, received_token: str | None) -> None:
    if not settings.app_access_token:
        return

    # compare_digest avoids leaking information through response time.
    is_valid = received_token is not None and hmac.compare_digest(
        received_token.encode("utf-8"), settings.app_access_token.encode("utf-8")
    )

    if not is_valid:
        raise AnalysisServiceError("unauthorized", "Missing or invalid access token.", 401)


def _load_default_settings() -> Settings:
    backend_directory = Path(__file__).resolve().parent.parent
    environment = dict(load_environment_file(backend_directory / ".env"))

    # Real environment variables win over the .env file.
    environment.update(os.environ)
    return Settings.from_environment(environment)


def create_application(settings: Settings | None = None, provider: AiProvider | None = None) -> FastAPI:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")

    active_settings = settings or _load_default_settings()
    transport: HttpxJsonTransport | None = None

    if provider is None:
        transport = HttpxJsonTransport()
        provider = GemmaGeminiProvider(settings=active_settings, transport=transport)

    analysis_service = AnalysisService(
        settings=active_settings,
        provider=provider,
        cache=ExpiringCache[AnalysisResult](
            maximum_entries=active_settings.cache_maximum_entries,
            time_to_live_seconds=active_settings.cache_time_to_live_seconds,
        ),
        client_rate_limiter=SlidingWindowRateLimiter(
            maximum_requests=active_settings.client_requests_per_minute, window_seconds=60
        ),
        global_rate_limiter=SlidingWindowRateLimiter(
            maximum_requests=active_settings.global_requests_per_minute, window_seconds=60
        ),
    )

    @asynccontextmanager
    async def lifespan(application: FastAPI):
        yield

        if transport is not None:
            await transport.close()

    documentation_url = "/docs" if active_settings.enable_api_documentation else None
    application = FastAPI(
        title="Zero Trust backend",
        version="0.2.0",
        docs_url=documentation_url,
        redoc_url=None,
        openapi_url="/openapi.json" if active_settings.enable_api_documentation else None,
        lifespan=lifespan,
    )

    @application.exception_handler(AnalysisServiceError)
    async def handle_service_error(request: Request, error: AnalysisServiceError) -> JSONResponse:
        return _build_error_response(error.code, error.message, error.http_status, error.retry_after_seconds)

    @application.exception_handler(InputValidationError)
    async def handle_validation_error(request: Request, error: InputValidationError) -> JSONResponse:
        return _build_error_response(error.code, error.message, error.http_status)

    @application.exception_handler(Exception)
    async def handle_unexpected_error(request: Request, error: Exception) -> JSONResponse:
        # Only the error type is logged: the message could contain user content.
        _LOGGER.error("unexpected error type=%s", type(error).__name__)
        return _build_error_response("internal_error", "Internal server error.", 500)

    def get_client_identifier(request: Request) -> str:
        return request.client.host if request.client else "unknown"

    @application.get("/health")
    async def health() -> dict:
        return {"status": "ok", "aiConfigured": active_settings.is_ai_configured}

    @application.post("/v1/analyze")
    async def analyze_text(
        request: Request,
        body: AnalyzeTextRequest,
        x_radar_access_token: str | None = Header(default=None),
    ) -> dict:
        _verify_access_token(active_settings, x_radar_access_token)
        result = await analysis_service.analyze_text(
            raw_text=body.text, client_identifier=get_client_identifier(request)
        )
        return result.to_response_dict()

    @application.post("/v1/analyze-image")
    async def analyze_image(
        request: Request,
        image: UploadFile = File(...),
        x_radar_access_token: str | None = Header(default=None),
    ) -> dict:
        _verify_access_token(active_settings, x_radar_access_token)

        # Read one byte more than the limit: it is enough to detect a file that is too large.
        image_bytes = await image.read(active_settings.maximum_image_bytes + 1)
        result = await analysis_service.analyze_image(
            image_bytes=image_bytes, client_identifier=get_client_identifier(request)
        )
        return result.to_response_dict()

    return application


application = create_application()
