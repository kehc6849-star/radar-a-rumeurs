import tempfile
import unittest
from pathlib import Path

from app.config import ConfigurationError, Settings, load_environment_file


class SettingsTest(unittest.TestCase):
    def test_default_values_are_safe(self) -> None:
        settings = Settings.from_environment({})

        self.assertFalse(settings.is_ai_configured)
        self.assertEqual(settings.primary_model_name, "gemma-4-26b-a4b-it")
        self.assertEqual(settings.fallback_model_name, "gemma-4-31b-it")
        self.assertFalse(settings.enable_api_documentation)

    def test_values_are_read_from_environment(self) -> None:
        settings = Settings.from_environment(
            {
                "GEMINI_API_KEY": " secret-key ",
                "AI_MODEL": "other-model",
                "CLIENT_REQUESTS_PER_MINUTE": "3",
                "ENABLE_API_DOCUMENTATION": "true",
                "AI_BASE_URL": "https://example.test/v1/",
            }
        )

        self.assertTrue(settings.is_ai_configured)
        self.assertEqual(settings.gemini_api_key, "secret-key")
        self.assertEqual(settings.primary_model_name, "other-model")
        self.assertEqual(settings.client_requests_per_minute, 3)
        self.assertTrue(settings.enable_api_documentation)
        self.assertEqual(settings.api_base_url, "https://example.test/v1")

    def test_invalid_number_is_rejected(self) -> None:
        with self.assertRaises(ConfigurationError):
            Settings.from_environment({"CLIENT_REQUESTS_PER_MINUTE": "abc"})

        with self.assertRaises(ConfigurationError):
            Settings.from_environment({"GLOBAL_REQUESTS_PER_MINUTE": "0"})


class EnvironmentFileTest(unittest.TestCase):
    def test_missing_file_gives_empty_values(self) -> None:
        self.assertEqual(load_environment_file(Path("does-not-exist.env")), {})

    def test_file_is_parsed(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            file_path = Path(directory_name) / ".env"
            file_path.write_text(
                "# comment\n\nGEMINI_API_KEY=abc123\nAPP_ACCESS_TOKEN=\"quoted value\"\nBROKEN LINE\n",
                encoding="utf-8",
            )

            values = load_environment_file(file_path)

        self.assertEqual(values["GEMINI_API_KEY"], "abc123")
        self.assertEqual(values["APP_ACCESS_TOKEN"], "quoted value")
        self.assertNotIn("BROKEN LINE", values)


if __name__ == "__main__":
    unittest.main()
