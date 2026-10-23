import pytest

from app.integrations.ai.grounded_ai import GroundedAIService
from app.integrations.ai.safety_triage import detect_safety


def test_reported_severe_headache_and_vision_change_is_emergency():
    result = detect_safety("I have a sudden severe headache and blurred vision")
    assert result.emergency is True
    assert result.level == "emergency"


def test_educational_hypothetical_does_not_trigger_emergency():
    result = detect_safety("Could severe headache with blurred vision be dangerous?")
    assert result.emergency is False
    assert detect_safety("What if my severe headache and blurred vision gets worse?").emergency is False
    assert detect_safety("My question is whether severe headache with blurred vision is urgent").emergency is False


def test_clear_negation_does_not_trigger_for_denied_symptom():
    result = detect_safety("I do not have chest pain")
    assert result.emergency is False


def test_negated_symptom_does_not_hide_another_concerning_symptom():
    result = detect_safety("I am not having chest pain, but I have trouble breathing")
    assert result.emergency is True
    assert "breathing_difficulty" in result.matched_rules


def test_reported_non_emergency_symptom_is_not_classified_as_safe():
    result = detect_safety("I have nausea and vomiting")
    assert result.level == "professional_review"
    assert result.requires_professional_review is True


@pytest.mark.asyncio
async def test_emergency_path_does_not_need_database_or_retrieval(monkeypatch):
    async def fail_if_retrieved(*args, **kwargs):
        raise AssertionError("emergency path must not access retrieval")

    monkeypatch.setattr("app.integrations.ai.grounded_ai.retrieve", fail_if_retrieved)
    response = await GroundedAIService().answer_maternal_query(
        "I have sudden severe headache and blurred vision", db=None,
    )
    assert response.safety_escalation is True
    assert response.generation_mode == "rules_only"
    assert "URGENT CLINICAL NOTICE" in response.answer


@pytest.mark.asyncio
async def test_report_text_cannot_downgrade_symptom_review():
    response = await GroundedAIService().answer_maternal_query(
        "I have a persistent headache", db=None,
        report_text="Hemoglobin: 11 g/dL. No additional notes.",
    )
    assert response.safety_level == "professional_review"
    assert response.requires_professional_review is True
