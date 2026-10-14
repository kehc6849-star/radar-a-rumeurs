import asyncio
import unittest

from app.ai_provider import (
    AiProviderError,
    AiProviderErrorKind,
    GemmaGeminiProvider,
    HttpJsonResponse,
    HttpTransportError,
    ImagePayload,
)
from app.config import Settings


class FakeTransport:
    """Returns prepared answers, one per call, and remembers the requests."""

    def __init__(self, answers: list) -> None:
        self._answers = list(answers)
        self.requests: list[dict] = []

    async def post_json(self, *, url: str, headers: dict, payload: dict, timeout_seconds: float) -> HttpJsonResponse:
        self.requests.append({"url": url, "headers": headers, "payload": payload})
        answer = self._answers.pop(0)

        if isinstance(answer, Exception):
            raise answer

        return answer


def build_success_body(text: str, thought_text: str | None = None) -> dict:
    parts = []

    if thought_text is not None:
        parts.append({"text": thought_text, "thought": True})

    parts.append({"text": text})
    return {
        "candidates": [{"content": {"parts": parts}, "finishReason": "STOP"}],
        "usageMetadata": {"totalTokenCount": 321},
    }


def run(coroutine):
    return asyncio.run(coroutine)


class GemmaGeminiProviderTest(unittest.TestCase):
    def setUp(self) -> None:
        self.settings = Settings(gemini_api_key="test-key")

    def test_text_request_shape_and_answer(self) -> None:
        transport = FakeTransport([HttpJsonResponse(200, build_success_body('{"riskScore": 1}', "thinking..."))])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        output = run(provider.generate_verdict(user_prompt="hello", image=None))

        self.assertEqual(output.raw_text, '{"riskScore": 1}')
        self.assertEqual(output.model_name, "gemma-4-26b-a4b-it")
        self.assertEqual(output.total_token_count, 321)

        request = transport.requests[0]
        self.assertTrue(request["url"].endswith("/models/gemma-4-26b-a4b-it:generateContent"))
        self.assertEqual(request["headers"]["x-goog-api-key"], "test-key")
        self.assertEqual(request["payload"]["generationConfig"]["thinkingConfig"]["thinkingLevel"], "minimal")
        self.assertIn("systemInstruction", request["payload"])

    def test_image_is_sent_inline_before_the_text(self) -> None:
        transport = FakeTransport([HttpJsonResponse(200, build_success_body("{}"))])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        run(
            provider.generate_verdict(
                user_prompt="read it", image=ImagePayload(image_bytes=b"\x89PNG-data", mime_type="image/png")
            )
        )

        parts = transport.requests[0]["payload"]["contents"][0]["parts"]
        self.assertIn("inline_data", parts[0])
        self.assertEqual(parts[0]["inline_data"]["mime_type"], "image/png")
        self.assertEqual(parts[1], {"text": "read it"})

    def test_thinking_option_can_be_disabled(self) -> None:
        transport = FakeTransport([HttpJsonResponse(200, build_success_body("{}"))])
        provider = GemmaGeminiProvider(settings=Settings(gemini_api_key="k", thinking_level=""), transport=transport)

        run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertNotIn("thinkingConfig", transport.requests[0]["payload"]["generationConfig"])

    def test_fallback_model_is_used_when_quota_is_exhausted(self) -> None:
        transport = FakeTransport([HttpJsonResponse(429, None), HttpJsonResponse(200, build_success_body("{}"))])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        output = run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(output.model_name, "gemma-4-31b-it")
        self.assertEqual(len(transport.requests), 2)

    def test_rate_limit_error_when_both_models_are_exhausted(self) -> None:
        transport = FakeTransport([HttpJsonResponse(429, None), HttpJsonResponse(429, None)])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.RATE_LIMITED)

    def test_network_failure_becomes_unavailable(self) -> None:
        transport = FakeTransport([HttpTransportError("down"), HttpTransportError("down")])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.UNAVAILABLE)

    def test_refused_key_is_not_retried(self) -> None:
        transport = FakeTransport([HttpJsonResponse(403, None)])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.NOT_CONFIGURED)
        self.assertEqual(len(transport.requests), 1)

    def test_safety_block_is_reported(self) -> None:
        blocked_body = {"candidates": [{"finishReason": "SAFETY"}]}
        transport = FakeTransport([HttpJsonResponse(200, blocked_body)])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.BLOCKED)

    def test_prompt_block_without_candidates_is_reported(self) -> None:
        transport = FakeTransport([HttpJsonResponse(200, {"promptFeedback": {"blockReason": "OTHER"}})])
        provider = GemmaGeminiProvider(settings=self.settings, transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.BLOCKED)

    def test_missing_key_fails_before_any_network_call(self) -> None:
        transport = FakeTransport([])
        provider = GemmaGeminiProvider(settings=Settings(gemini_api_key=""), transport=transport)

        with self.assertRaises(AiProviderError) as context:
            run(provider.generate_verdict(user_prompt="x", image=None))

        self.assertEqual(context.exception.kind, AiProviderErrorKind.NOT_CONFIGURED)
        self.assertEqual(transport.requests, [])

    def test_unreadable_answers_are_invalid(self) -> None:
        for answer in (HttpJsonResponse(200, None), HttpJsonResponse(200, {"candidates": []}), HttpJsonResponse(200, {"candidates": [{"content": {"parts": [{"text": "x", "thought": True}]}}]})):
            with self.subTest(answer=answer):
                provider = GemmaGeminiProvider(settings=self.settings, transport=FakeTransport([answer]))

                with self.assertRaises(AiProviderError) as context:
                    run(provider.generate_verdict(user_prompt="x", image=None))

                self.assertEqual(context.exception.kind, AiProviderErrorKind.INVALID_RESPONSE)


if __name__ == "__main__":
    unittest.main()
