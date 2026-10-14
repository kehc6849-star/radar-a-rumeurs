"""Application settings, read from environment variables and an optional .env file."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


class ConfigurationError(Exception):
    """Raised when a setting has an invalid value."""


def load_environment_file(file_path: Path) -> dict[str, str]:
    """Read simple KEY=VALUE lines from a .env file.

    A tiny reader is used on purpose: it avoids one more dependency.
    A missing file is not an error (the real environment may hold the values).
    """
    if not file_path.is_file():
        return {}

    values: dict[str, str] = {}

    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#") or "=" not in line:
            continue

        name, _, value = line.partition("=")
        cleaned_value = value.strip()

        if len(cleaned_value) >= 2 and cleaned_value[0] == cleaned_value[-1] and cleaned_value[0] in "\"'":
            cleaned_value = cleaned_value[1:-1]

        values[name.strip()] = cleaned_value

    return values


def _read_text(environment: Mapping[str, str], name: str, default: str) -> str:
    value = environment.get(name)

    if value is None:
        return default

    return value.strip()


def _read_positive_integer(environment: Mapping[str, str], name: str, default: int) -> int:
    raw_value = environment.get(name)

    if raw_value is None or not raw_value.strip():
        return default

    try:
        parsed_value = int(raw_value.strip())
    except ValueError as error:
        raise ConfigurationError(f"{name} must be a whole number.") from error

    if parsed_value <= 0:
        raise ConfigurationError(f"{name} must be greater than zero.")

    return parsed_value


def _read_boolean(environment: Mapping[str, str], name: str, default: bool) -> bool:
    raw_value = environment.get(name)

    if raw_value is None or not raw_value.strip():
        return default

    return raw_value.strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class Settings:
    gemini_api_key: str = ""
    primary_model_name: str = "gemma-4-26b-a4b-it"
    fallback_model_name: str = "gemma-4-31b-it"
    api_base_url: str = "https://generativelanguage.googleapis.com/v1beta"
    request_timeout_seconds: float = 30.0
    thinking_level: str = "minimal"
    maximum_output_tokens: int = 900
    maximum_text_characters: int = 5000
    maximum_ai_input_characters: int = 3000
    maximum_image_bytes: int = 4_000_000
    client_requests_per_minute: int = 10
    global_requests_per_minute: int = 12
    cache_time_to_live_seconds: int = 3600
    cache_maximum_entries: int = 500
    app_access_token: str = ""
    enable_api_documentation: bool = False

    @property
    def is_ai_configured(self) -> bool:
        return bool(self.gemini_api_key.strip())

    @classmethod
    def from_environment(cls, environment: Mapping[str, str]) -> "Settings":
        return cls(
            gemini_api_key=_read_text(environment, "GEMINI_API_KEY", ""),
            primary_model_name=_read_text(environment, "AI_MODEL", cls.primary_model_name),
            fallback_model_name=_read_text(environment, "AI_FALLBACK_MODEL", cls.fallback_model_name),
            api_base_url=_read_text(environment, "AI_BASE_URL", cls.api_base_url).rstrip("/"),
            thinking_level=_read_text(environment, "AI_THINKING_LEVEL", cls.thinking_level),
            maximum_output_tokens=_read_positive_integer(environment, "AI_MAX_OUTPUT_TOKENS", cls.maximum_output_tokens),
            maximum_text_characters=_read_positive_integer(environment, "MAX_TEXT_CHARACTERS", cls.maximum_text_characters),
            maximum_ai_input_characters=_read_positive_integer(
                environment, "MAX_AI_INPUT_CHARACTERS", cls.maximum_ai_input_characters
            ),
            maximum_image_bytes=_read_positive_integer(environment, "MAX_IMAGE_BYTES", cls.maximum_image_bytes),
            client_requests_per_minute=_read_positive_integer(
                environment, "CLIENT_REQUESTS_PER_MINUTE", cls.client_requests_per_minute
            ),
            global_requests_per_minute=_read_positive_integer(
                environment, "GLOBAL_REQUESTS_PER_MINUTE", cls.global_requests_per_minute
            ),
            cache_time_to_live_seconds=_read_positive_integer(
                environment, "CACHE_TIME_TO_LIVE_SECONDS", cls.cache_time_to_live_seconds
            ),
            cache_maximum_entries=_read_positive_integer(environment, "CACHE_MAX_ENTRIES", cls.cache_maximum_entries),
            app_access_token=_read_text(environment, "APP_ACCESS_TOKEN", ""),
            enable_api_documentation=_read_boolean(environment, "ENABLE_API_DOCUMENTATION", False),
        )
