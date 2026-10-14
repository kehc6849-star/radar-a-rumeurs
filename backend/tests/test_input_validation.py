import unittest

from app.input_validation import InputValidationError, detect_image_mime_type, sanitize_text, validate_image

JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 20
PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 20
WEBP_BYTES = b"RIFF\x00\x00\x00\x00WEBPVP8 " + b"\x00" * 10


class SanitizeTextTest(unittest.TestCase):
    def test_text_is_trimmed_and_control_characters_removed(self) -> None:
        self.assertEqual(sanitize_text("  bonjour\x00 le monde \x07 ", 100), "bonjour  le monde")

    def test_empty_text_is_rejected(self) -> None:
        with self.assertRaises(InputValidationError) as context:
            sanitize_text("   \x00  ", 100)

        self.assertEqual(context.exception.code, "empty_text")

    def test_non_string_is_rejected(self) -> None:
        with self.assertRaises(InputValidationError):
            sanitize_text(None, 100)

        with self.assertRaises(InputValidationError):
            sanitize_text(123, 100)

    def test_too_long_text_is_rejected(self) -> None:
        with self.assertRaises(InputValidationError) as context:
            sanitize_text("a" * 101, 100)

        self.assertEqual(context.exception.http_status, 413)


class ImageValidationTest(unittest.TestCase):
    def test_supported_formats_are_detected_from_content(self) -> None:
        self.assertEqual(detect_image_mime_type(JPEG_BYTES), "image/jpeg")
        self.assertEqual(detect_image_mime_type(PNG_BYTES), "image/png")
        self.assertEqual(detect_image_mime_type(WEBP_BYTES), "image/webp")

    def test_unknown_content_is_not_an_image(self) -> None:
        self.assertIsNone(detect_image_mime_type(b"This is not an image at all"))
        self.assertIsNone(detect_image_mime_type(b"short"))

    def test_validate_image_guards(self) -> None:
        self.assertEqual(validate_image(PNG_BYTES, 1000), "image/png")

        with self.assertRaises(InputValidationError) as empty_context:
            validate_image(b"", 1000)

        self.assertEqual(empty_context.exception.code, "empty_image")

        with self.assertRaises(InputValidationError) as large_context:
            validate_image(PNG_BYTES, 10)

        self.assertEqual(large_context.exception.code, "image_too_large")

        with self.assertRaises(InputValidationError) as format_context:
            validate_image(b"GIF89a" + b"\x00" * 20, 1000)

        self.assertEqual(format_context.exception.code, "unsupported_image")


if __name__ == "__main__":
    unittest.main()
