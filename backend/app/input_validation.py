"""Guard clauses for everything that comes from the outside world."""

from __future__ import annotations

import re

# Control characters have no meaning in a message and can confuse the model.
_CONTROL_CHARACTERS_PATTERN = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


class InputValidationError(Exception):
    """The request content is not acceptable. The message is safe to show."""

    def __init__(self, code: str, message: str, http_status: int = 422) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = http_status


def sanitize_text(raw_text: object, maximum_characters: int) -> str:
    """Return a cleaned text, or raise InputValidationError."""
    if not isinstance(raw_text, str):
        raise InputValidationError("invalid_text", "The text must be a string.")

    cleaned_text = _CONTROL_CHARACTERS_PATTERN.sub(" ", raw_text).strip()

    if not cleaned_text:
        raise InputValidationError("empty_text", "The text is empty.")

    if len(cleaned_text) > maximum_characters:
        raise InputValidationError(
            "text_too_long",
            f"The text is too long (maximum {maximum_characters} characters).",
            http_status=413,
        )

    return cleaned_text


def detect_image_mime_type(image_bytes: bytes) -> str | None:
    """Detect the image type from its first bytes.

    The file name and the declared content type are never trusted:
    only the real content decides.
    """
    if len(image_bytes) < 12:
        return None

    if image_bytes[:3] == b"\xff\xd8\xff":
        return "image/jpeg"

    if image_bytes[:4] == b"\x89PNG":
        return "image/png"

    if image_bytes[:4] == b"RIFF" and image_bytes[8:12] == b"WEBP":
        return "image/webp"

    return None


def validate_image(image_bytes: bytes, maximum_image_bytes: int) -> str:
    """Return the detected mime type, or raise InputValidationError."""
    if not image_bytes:
        raise InputValidationError("empty_image", "The image is empty.")

    if len(image_bytes) > maximum_image_bytes:
        raise InputValidationError("image_too_large", "The image is too large.", http_status=413)

    mime_type = detect_image_mime_type(image_bytes)

    if mime_type is None:
        raise InputValidationError(
            "unsupported_image", "Unsupported image format. Use JPEG, PNG or WebP.", http_status=415
        )

    return mime_type
