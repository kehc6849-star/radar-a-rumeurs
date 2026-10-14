"""Turns the raw model answer into a checked, bounded verdict.

The model answer is never trusted as is: every field is checked, cut to a
safe length, and unknown values are dropped.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass

ALLOWED_THREAT_FAMILIES = (
    "mobileMoneyFraud",
    "scholarshipScam",
    "phishing",
    "fraudulentOffer",
    "misinformation",
)

MAXIMUM_SIGNALS = 5
MAXIMUM_ACTIONS = 4
MAXIMUM_TITLE_LENGTH = 80
MAXIMUM_EXPLANATION_LENGTH = 300
MAXIMUM_ACTION_LENGTH = 200
MAXIMUM_EXTRACTED_TEXT_LENGTH = 1500

_CODE_FENCE_PATTERN = re.compile(r"```(?:json)?", re.IGNORECASE)


class VerdictParsingError(Exception):
    """The model answer cannot be used."""


@dataclass(frozen=True)
class AiSignal:
    title: str
    explanation: str


@dataclass(frozen=True)
class AiVerdict:
    risk_score: int
    threat_family: str | None
    signals: tuple[AiSignal, ...]
    recommended_actions: tuple[str, ...]
    extracted_text: str


def _extract_json_object(raw_text: str) -> dict:
    cleaned_text = _CODE_FENCE_PATTERN.sub("", raw_text)
    start_index = cleaned_text.find("{")
    end_index = cleaned_text.rfind("}")

    if start_index == -1 or end_index <= start_index:
        raise VerdictParsingError("No JSON object found in the model answer.")

    try:
        parsed_value = json.loads(cleaned_text[start_index : end_index + 1])
    except json.JSONDecodeError as error:
        raise VerdictParsingError("The model answer is not valid JSON.") from error

    if not isinstance(parsed_value, dict):
        raise VerdictParsingError("The model answer is not a JSON object.")

    return parsed_value


def _coerce_risk_score(value: object) -> int:
    # bool is a subclass of int in Python: refuse it explicitly.
    if isinstance(value, bool):
        raise VerdictParsingError("riskScore must be a number.")

    if isinstance(value, (int, float)):
        numeric_value = float(value)
    elif isinstance(value, str):
        try:
            numeric_value = float(value.strip())
        except ValueError as error:
            raise VerdictParsingError("riskScore must be a number.") from error
    else:
        raise VerdictParsingError("riskScore is missing.")

    if numeric_value != numeric_value:  # NaN check
        raise VerdictParsingError("riskScore must be a number.")

    return max(0, min(100, int(round(numeric_value))))


def _clean_text(value: object, maximum_length: int) -> str:
    if not isinstance(value, str):
        return ""

    return " ".join(value.split())[:maximum_length]


def parse_ai_verdict(raw_text: str) -> AiVerdict:
    if not isinstance(raw_text, str) or not raw_text.strip():
        raise VerdictParsingError("The model answer is empty.")

    answer = _extract_json_object(raw_text)
    risk_score = _coerce_risk_score(answer.get("riskScore"))

    raw_family = answer.get("threatFamily")
    threat_family = raw_family if isinstance(raw_family, str) and raw_family in ALLOWED_THREAT_FAMILIES else None

    signals: list[AiSignal] = []
    raw_signals = answer.get("signals")

    if isinstance(raw_signals, list):
        for raw_signal in raw_signals:
            if len(signals) >= MAXIMUM_SIGNALS:
                break

            if not isinstance(raw_signal, dict):
                continue

            title = _clean_text(raw_signal.get("title"), MAXIMUM_TITLE_LENGTH)
            explanation = _clean_text(raw_signal.get("explanation"), MAXIMUM_EXPLANATION_LENGTH)

            if title and explanation:
                signals.append(AiSignal(title=title, explanation=explanation))

    actions: list[str] = []
    raw_actions = answer.get("recommendedActions")

    if isinstance(raw_actions, list):
        for raw_action in raw_actions:
            if len(actions) >= MAXIMUM_ACTIONS:
                break

            action = _clean_text(raw_action, MAXIMUM_ACTION_LENGTH)

            if action:
                actions.append(action)

    extracted_text = _clean_text(answer.get("extractedText"), MAXIMUM_EXTRACTED_TEXT_LENGTH)

    return AiVerdict(
        risk_score=risk_score,
        threat_family=threat_family,
        signals=tuple(signals),
        recommended_actions=tuple(actions),
        extracted_text=extracted_text,
    )
