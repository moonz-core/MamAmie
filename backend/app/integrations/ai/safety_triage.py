"""Deterministic, independent warning-sign screening.

This is a conservative hackathon ruleset, not a clinically validated protocol.
It runs before retrieval or generation and must receive qualified clinical review
before any reliability claim or production triage use.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional


RULE_SOURCE = {
    "title": "Booklet for Expecting Mothers",
    "source": "National Health Mission, Government of India",
    "original_url": "https://www.nhm.gov.in/images/pdf/programmes/maternal-health/guidelines/my_safe_motherhood_booklet_english.pdf",
    "summary": "The booklet lists bleeding, convulsions, fever and severe abdominal pain among pregnancy danger signals; the local rules are a conservative demonstration and are not a full protocol.",
}
RMNCH_SOURCE = {
    "title": "Handbook for RMNCH Counsellors",
    "source": "Ministry of Health and Family Welfare / National Health Mission, Government of India",
    "original_url": "https://nhm.gov.in/images/pdf/programmes/family-planing/guidelines/Handbook%20for%20RMNCH%20Counsellors-final-Oct%2027,%202012%20revised-mohfw-cg.pdf",
    "summary": "The handbook lists vaginal bleeding, convulsions, severe headache with blurred vision, loss of fetal movement, high fever with marked weakness, severe abdominal pain, and difficult breathing among pregnancy danger signs.",
}
POSTPARTUM_SOURCE = {
    "title": "Keeping well during pregnancy and after childbirth",
    "source": "World Health Organization",
    "original_url": "https://www.who.int/tools/your-life-your-health/life-phase/pregnancy--birth-and-after-childbirth/keeping-well-during-pregnancy-and-after-childbirth",
    "summary": "WHO public guidance advises health-worker support for danger signs and thoughts of harming oneself or the baby.",
}
EMERGENCY_NUMBER_SOURCE = {
    "title": "Emergency Response Support System in India",
    "source": "Ministry of Home Affairs, Government of India",
    "original_url": "https://112.gov.in/",
    "summary": "The official service page describes 112 as India's pan-India emergency response number.",
}

SELF_REPORT_RE = re.compile(
    r"\b(?:i\s+(?:have|am|feel|felt|noticed|experience|experienced|had|want|do not have|don't have|haven't had|have no)|"
    r"i['\u2019]m|my\s+(?:headache|pain|bleeding|spotting|breathing|breath|symptoms?|baby)|currently|right now|experiencing)\b", re.I
)
HYPOTHETICAL_RE = re.compile(
    r"\b(?:if|what if|suppose|hypothetically|when)\s+(?:(?:i|someone|a person)\s+(?:had|have|am|were|was|experienced|experience|felt|feel)|my)\b", re.I
)

# Reviewed clinical limits are intentionally absent; every rule is tagged as demo/unreviewed.
EMERGENCY_RULES = [
    ("seizure", re.compile(r"\b(?:seizures?|convulsions?|fits?)\b", re.I)),
    ("loss_of_consciousness", re.compile(r"\b(?:passed out|fainted|unconscious|not waking|loss of consciousness)\b", re.I)),
    ("breathing_difficulty", re.compile(r"\b(?:severe (?:shortness of breath|breathlessness)|difficulty breathing|trouble breathing|can't breathe|cannot breathe|gasping)\b", re.I)),
    ("chest_pain", re.compile(r"\b(?:chest pain|pain in (?:my )?chest|chest tightness)\b", re.I)),
    ("vaginal_bleeding", re.compile(r"\b(?:vaginal )?(?:bleeding|bleedin|bleedng|spotting)\b", re.I)),
    ("severe_abdominal_pain", re.compile(r"\b(?:severe|unbearable|extreme)\s+(?:abdominal|belly|stomach)\s+pain\b|\b(?:severe|unbearable) (?:stomach|belly) ache\b", re.I)),
    ("reduced_fetal_movement", re.compile(r"\b(?:reduced|less|decreased|no|absent)\s+(?:fetal|foetal|baby'?s?)\s+movement\b|\b(?:baby|baby's) (?:hasn't|has not|isn't|is not) moved\b|\b(?:baby|baby's) (?:is )?not moving\b|\bnot feeling (?:the )?baby move\b", re.I)),
    ("severe_headache_with_visual_change", re.compile(r"\b(?:severe|bad|sudden) headache\b", re.I)),
    ("self_harm", re.compile(r"\b(?:i want to (?:die|kill myself|hurt myself)|i(?:'m| am) going to (?:hurt|kill) myself|suicidal|self[- ]harm|thoughts? of (?:killing|hurting) myself)\b", re.I)),
    ("fever_with_deterioration", re.compile(r"\b(?:high )?fever\b", re.I)),
    ("newborn_danger_sign", re.compile(r"\b(?:newborn|infant|baby)\b.{0,70}\b(?:not feeding|cannot feed|difficulty breathing|fast breathing|convulsion|seizure|very cold|unresponsive|hard to wake)\b", re.I)),
]
VISION_RE = re.compile(r"\b(?:blurred vision|blurry vision|seeing spots|flashing lights|vision changes|visual disturbance)\b", re.I)
DETERIORATION_RE = re.compile(r"\b(?:confused|confusion|too weak to get out of bed|rapidly getting worse|rapid deterioration|very weak)\b", re.I)
SYMPTOM_RE = re.compile(r"\b(?:pain|ache|bleed|bleeding|spotting|fever|headache|dizzy|vomit|vomiting|breathless|breathlessness|rash|swelling|swollen|sad|anxious|worry|movement|feeding|latch|milk supply)\b", re.I)


@dataclass
class SafetyResult:
    level: str = "educational"
    emergency: bool = False
    requires_professional_review: bool = False
    message: Optional[str] = None
    matched_rules: tuple[str, ...] = ()


def _clauses(text: str) -> list[str]:
    return [part.strip() for part in re.split(r"[.!?;,]|\bbut\b|\bhowever\b", text) if part.strip()]


def _is_negated(clause: str, match: re.Match[str]) -> bool:
    before = clause[:match.start()][-90:]
    # A clear denial immediately governing this symptom suppresses it; uncertainty
    # phrases such as "I don't know if my chest pain is serious" do not.
    return bool(re.search(
        r"\b(?:i am not|i'm not|i have no|i do not have|i don't have|i haven't had|"
        r"no|never|without|not having|not experiencing|not feeling|denies|denied)"
        r"\s+(?:(?:any|a|the|my|had|having|experiencing|feeling|of|currently|vaginal|heavy|severe|chest|abdominal|belly|stomach|fetal|foetal|blurred|blurry|vision|breathing|short|of|breath|pain|headache|fever|blood|movement|symptoms?)\s+){0,5}$",
        before,
        re.I,
    ))


def detect_safety(text: str, *, stage: Optional[str] = None, assume_reported: bool = False) -> SafetyResult:
    normalized = re.sub(r"\s+", " ", text.casefold())
    reported = assume_reported or bool(SELF_REPORT_RE.search(normalized))
    if re.match(r"^i\s+have\s+(?:a\s+)?question\b", normalized):
        reported = assume_reported
    if not normalized.strip():
        return SafetyResult(level="professional_review", requires_professional_review=True,
                            message="I don’t have enough information to assess a concern. If something feels urgent, contact local emergency services or a healthcare professional.")

    found: list[str] = []
    symptom_mentioned = False
    for clause in _clauses(normalized):
        if HYPOTHETICAL_RE.search(clause):
            continue
        if SYMPTOM_RE.search(clause):
            symptom_mentioned = True
        for rule_name, pattern in EMERGENCY_RULES:
            match = pattern.search(clause)
            if not match or _is_negated(clause, match):
                continue
            # General questions and hypotheticals do not assert that the user has a symptom.
            if not reported:
                continue
            if rule_name == "severe_headache_with_visual_change":
                visual = VISION_RE.search(clause)
                if not visual or _is_negated(clause, visual):
                    continue
            if rule_name == "fever_with_deterioration":
                deterioration = DETERIORATION_RE.search(clause)
                if not deterioration or _is_negated(clause, deterioration):
                    continue
            found.append(rule_name)

    if found:
        return SafetyResult(
            level="emergency", emergency=True, requires_professional_review=True,
            matched_rules=tuple(dict.fromkeys(found)),
            message=("A symptom you described may need urgent assessment. Do not wait for an app response. "
                     "Contact your maternity team or go to the nearest emergency department now. "
                     "If you are in India, call 112; elsewhere contact your local emergency number. "
                     "Ask someone you trust to stay with you if possible."),
        )

    if symptom_mentioned and reported:
        return SafetyResult(
            level="professional_review", requires_professional_review=True,
            message=("I can’t determine the cause or rule out a serious problem here. Contact your maternity or healthcare team "
                     "for advice, especially if the symptom is new, severe, worsening, or worrying to you. If you think it is an emergency, seek urgent care now."),
        )

    if assume_reported:
        return SafetyResult(
            level="professional_review", requires_professional_review=True,
            message=("I can’t classify symptoms as safe from a chat. If you have a warning sign, symptoms are severe or worsening, "
                     "or you feel unsafe, contact a healthcare professional promptly or local emergency services."),
        )

    return SafetyResult()


def safety_citations(rule_names: tuple[str, ...]) -> list[dict]:
    citations = [RMNCH_SOURCE]
    if any(rule in rule_names for rule in ("vaginal_bleeding", "seizure", "severe_abdominal_pain", "reduced_fetal_movement")):
        citations.insert(0, RULE_SOURCE)
    if "self_harm" in rule_names:
        citations.append(POSTPARTUM_SOURCE)
    if citations:
        citations.append(EMERGENCY_NUMBER_SOURCE)
    return citations
