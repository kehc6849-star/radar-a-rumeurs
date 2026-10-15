"""Turns the raw model answer into a checked, bounded verdict.

The model answer is never trusted as is: every field is checked, cut to a
safe length, and unknown values are dropped.

The texts shown to the user also get a small, predictable clean-up
(French quotation marks, no screen-colour words, no repeated items), so the
result stays consistent even when the model does not follow every style rule.
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

# A non-breaking space keeps the guillemets attached to the quoted words.
_NON_BREAKING_SPACE = "\u00a0"

# Straight single quotes: the opening quote must not follow a letter, so the
# apostrophes of "l'offre" or "n'ouvrez" are never taken as quotation marks.
_STRAIGHT_SINGLE_QUOTED_PATTERN = re.compile(
    r"(?<![\w'])'((?:[^'\n]|(?<=\w)'(?=\w))+?)'(?![\w'])"
)
_STRAIGHT_DOUBLE_QUOTED_PATTERN = re.compile(r'"([^"\n]+?)"')
_CURLY_DOUBLE_QUOTED_PATTERN = re.compile(r"\u201c([^\u201d\n]+?)\u201d")

# Already French quotes: only fix the spacing inside them.
_FRENCH_GUILLEMETS_PATTERN = re.compile(r"\u00ab\s*([^\u00ab\u00bb\n]+?)\s*\u00bb")

_QUOTED_TEXT_PATTERNS = (
    _STRAIGHT_SINGLE_QUOTED_PATTERN,
    _STRAIGHT_DOUBLE_QUOTED_PATTERN,
    _CURLY_DOUBLE_QUOTED_PATTERN,
    _FRENCH_GUILLEMETS_PATTERN,
)

# The advice must also be true for a pasted text, where no link has a colour.
_COLOURED_LINK_PATTERN = re.compile(r"\b(liens?)\s+bleus?\b", re.IGNORECASE)

_NON_ALPHANUMERIC_PATTERN = re.compile(r"[\W_]+")


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


def _wrap_in_french_guillemets(match: re.Match) -> str:
    quoted_text = match.group(1).strip()

    # Guard clause: never turn an empty quotation into empty guillemets.
    if not quoted_text:
        return match.group(0)

    return f"\u00ab{_NON_BREAKING_SPACE}{quoted_text}{_NON_BREAKING_SPACE}\u00bb"


def _apply_french_typography(text: str) -> str:
    typographic_text = text

    for quoted_text_pattern in _QUOTED_TEXT_PATTERNS:
        typographic_text = quoted_text_pattern.sub(_wrap_in_french_guillemets, typographic_text)

    return _COLOURED_LINK_PATTERN.sub(r"\1", typographic_text)


def _clean_text(
    value: object,
    maximum_length: int,
    should_apply_french_typography: bool = True,
) -> str:
    if not isinstance(value, str):
        return ""

    # Collapse spaces first: str.split() also removes non-breaking spaces,
    # so the typography step must come after it.
    single_spaced_text = " ".join(value.split())

    if should_apply_french_typography:
        single_spaced_text = _apply_french_typography(single_spaced_text)

    return single_spaced_text[:maximum_length].strip()


def _build_comparison_key(text: str) -> str:
    # Two texts that differ only by case, punctuation or spacing
    # are the same advice for the user, so they share one key.
    lowercase_text = text.casefold()

    return " ".join(_NON_ALPHANUMERIC_PATTERN.sub(" ", lowercase_text).split())


def parse_ai_verdict(raw_text: str) -> AiVerdict:
    if not isinstance(raw_text, str) or not raw_text.strip():
        raise VerdictParsingError("The model answer is empty.")

    answer = _extract_json_object(raw_text)
    risk_score = _coerce_risk_score(answer.get("riskScore"))

    raw_family = answer.get("threatFamily")
    threat_family = raw_family if isinstance(raw_family, str) and raw_family in ALLOWED_THREAT_FAMILIES else None

    signals: list[AiSignal] = []
    seen_signal_titles: set[str] = set()
    raw_signals = answer.get("signals")

    if isinstance(raw_signals, list):
        for raw_signal in raw_signals:
            if len(signals) >= MAXIMUM_SIGNALS:
                break

            if not isinstance(raw_signal, dict):
                continue

            title = _clean_text(raw_signal.get("title"), MAXIMUM_TITLE_LENGTH)
            explanation = _clean_text(raw_signal.get("explanation"), MAXIMUM_EXPLANATION_LENGTH)

            if not title or not explanation:
                continue

            title_key = _build_comparison_key(title)

            if title_key in seen_signal_titles:
                continue

            seen_signal_titles.add(title_key)
            signals.append(AiSignal(title=title, explanation=explanation))

    actions: list[str] = []
    seen_action_keys: set[str] = set()
    raw_actions = answer.get("recommendedActions")

    if isinstance(raw_actions, list):
        for raw_action in raw_actions:
            if len(actions) >= MAXIMUM_ACTIONS:
                break

            action = _clean_text(raw_action, MAXIMUM_ACTION_LENGTH)

            if not action:
                continue

            action_key = _build_comparison_key(action)

            if action_key in seen_action_keys:
                continue

            seen_action_keys.add(action_key)
            actions.append(action)

    # The text read from an image is kept as it is: no typography change.
    extracted_text = _clean_text(
        answer.get("extractedText"),
        MAXIMUM_EXTRACTED_TEXT_LENGTH,
        should_apply_french_typography=False,
    )

    return AiVerdict(
        risk_score=risk_score,
        threat_family=threat_family,
        signals=tuple(signals),
        recommended_actions=tuple(actions),
        extracted_text=extracted_text,
    )
