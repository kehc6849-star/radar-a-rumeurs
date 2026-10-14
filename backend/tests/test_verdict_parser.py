import unittest

from app.verdict_parser import VerdictParsingError, parse_ai_verdict


class ParseAiVerdictTest(unittest.TestCase):
    def test_clean_json_is_parsed(self) -> None:
        verdict = parse_ai_verdict(
            '{"riskScore": 82, "threatFamily": "mobileMoneyFraud",'
            ' "signals": [{"title": "Code demandé", "explanation": "Le message demande un code."}],'
            ' "recommendedActions": ["Ne donnez jamais votre code."], "extractedText": ""}'
        )

        self.assertEqual(verdict.risk_score, 82)
        self.assertEqual(verdict.threat_family, "mobileMoneyFraud")
        self.assertEqual(verdict.signals[0].title, "Code demandé")
        self.assertEqual(verdict.recommended_actions, ("Ne donnez jamais votre code.",))

    def test_code_fence_and_extra_words_are_tolerated(self) -> None:
        verdict = parse_ai_verdict('Voici le résultat :\n```json\n{"riskScore": 10, "signals": []}\n```')

        self.assertEqual(verdict.risk_score, 10)
        self.assertEqual(verdict.signals, ())

    def test_score_is_clamped_and_strings_are_accepted(self) -> None:
        self.assertEqual(parse_ai_verdict('{"riskScore": 250}').risk_score, 100)
        self.assertEqual(parse_ai_verdict('{"riskScore": -4}').risk_score, 0)
        self.assertEqual(parse_ai_verdict('{"riskScore": "37"}').risk_score, 37)
        self.assertEqual(parse_ai_verdict('{"riskScore": 49.6}').risk_score, 50)

    def test_unknown_family_is_dropped(self) -> None:
        self.assertIsNone(parse_ai_verdict('{"riskScore": 5, "threatFamily": "safe"}').threat_family)
        self.assertIsNone(parse_ai_verdict('{"riskScore": 5, "threatFamily": null}').threat_family)

    def test_lists_are_bounded_and_invalid_items_skipped(self) -> None:
        signals = ", ".join('{"title": "T%d", "explanation": "E%d"}' % (index, index) for index in range(9))
        verdict = parse_ai_verdict(
            '{"riskScore": 30, "signals": [%s, {"title": "", "explanation": "x"}, "text", 5],'
            ' "recommendedActions": ["a", "b", "c", "d", "e", ""]}' % signals
        )

        self.assertEqual(len(verdict.signals), 5)
        self.assertEqual(len(verdict.recommended_actions), 4)

    def test_long_text_is_cut(self) -> None:
        verdict = parse_ai_verdict('{"riskScore": 1, "extractedText": "%s"}' % ("x" * 5000))

        self.assertEqual(len(verdict.extracted_text), 1500)

    def test_bad_answers_are_rejected(self) -> None:
        for bad_answer in ("", "   ", "no json here", "{broken", "[1, 2]", '{"signals": []}', '{"riskScore": true}', '{"riskScore": "abc"}'):
            with self.subTest(answer=bad_answer):
                with self.assertRaises(VerdictParsingError):
                    parse_ai_verdict(bad_answer)


if __name__ == "__main__":
    unittest.main()
