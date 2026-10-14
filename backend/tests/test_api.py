import unittest

try:
    from fastapi.testclient import TestClient

    from app.ai_provider import AiProvider, ImagePayload, ProviderOutput
    from app.config import Settings
    from app.main import create_application

    DEPENDENCIES_AVAILABLE = True
except ImportError:  # pragma: no cover - the web libraries are not installed
    DEPENDENCIES_AVAILABLE = False

PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 20


if DEPENDENCIES_AVAILABLE:

    class FakeProvider(AiProvider):
        async def generate_verdict(self, *, user_prompt: str, image: ImagePayload | None) -> ProviderOutput:
            return ProviderOutput(
                raw_text='{"riskScore": 55, "threatFamily": "mobileMoneyFraud",'
                ' "signals": [{"title": "Code demandé", "explanation": "Explication."}],'
                ' "recommendedActions": ["Ne donnez rien."], "extractedText": "texte lu"}',
                model_name="fake-model",
                total_token_count=5,
            )


@unittest.skipUnless(DEPENDENCIES_AVAILABLE, "fastapi / httpx are not installed")
class ApiTest(unittest.TestCase):
    def build_client(self, **settings_overrides) -> "TestClient":
        settings = Settings(gemini_api_key="test-key", **settings_overrides)
        return TestClient(create_application(settings=settings, provider=FakeProvider()))

    def test_health(self) -> None:
        response = self.build_client().get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok", "aiConfigured": True})

    def test_analyze_text(self) -> None:
        response = self.build_client().post("/v1/analyze", json={"text": "Donnez-moi votre code"})

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["level"], "dangerous")
        self.assertEqual(body["riskScore"], 55)
        self.assertEqual(body["source"], "ai")
        self.assertEqual(body["signals"][0]["title"], "Code demandé")

    def test_empty_text_is_refused(self) -> None:
        response = self.build_client().post("/v1/analyze", json={"text": "   "})

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["error"]["code"], "empty_text")

    def test_access_token_is_checked_when_configured(self) -> None:
        client = self.build_client(app_access_token="secret-token")

        self.assertEqual(client.post("/v1/analyze", json={"text": "hello"}).status_code, 401)
        self.assertEqual(
            client.post("/v1/analyze", json={"text": "hello"}, headers={"X-Radar-Access-Token": "wrong"}).status_code,
            401,
        )
        self.assertEqual(
            client.post("/v1/analyze", json={"text": "hello"}, headers={"X-Radar-Access-Token": "secret-token"}).status_code,
            200,
        )

    def test_client_rate_limit_returns_retry_after(self) -> None:
        client = self.build_client(client_requests_per_minute=1)
        client.post("/v1/analyze", json={"text": "one"})
        response = client.post("/v1/analyze", json={"text": "two"})

        self.assertEqual(response.status_code, 429)
        self.assertIn("retry-after", response.headers)

    def test_analyze_image(self) -> None:
        response = self.build_client().post("/v1/analyze-image", files={"image": ("shot.png", PNG_BYTES, "image/png")})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["extractedText"], "texte lu")

    def test_bad_image_is_refused(self) -> None:
        response = self.build_client().post(
            "/v1/analyze-image", files={"image": ("shot.png", b"definitely not an image", "image/png")}
        )

        self.assertEqual(response.status_code, 415)


if __name__ == "__main__":
    unittest.main()
