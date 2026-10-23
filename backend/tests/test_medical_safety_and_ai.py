import pytest
from httpx import AsyncClient
from app.core.config import settings

pytestmark = pytest.mark.asyncio


async def test_ai_emergency_symptom_escalation(client: AsyncClient, auth_headers: dict):
    # Test Red Flag: Sudden severe headache and vision blurriness (Preeclampsia red flag)
    resp = await client.post(
        f"{settings.API_V1_PREFIX}/ai-assistant/query",
        headers=auth_headers,
        json={"query": "I have sudden severe headache and blurred vision"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["safety_escalation"] is True
    assert "URGENT CLINICAL NOTICE" in data["answer"]
    assert data["emergency_notice"] is not None

    # Test Red Flag: Bleeding and fluid leakage
    resp_bleed = await client.post(
        f"{settings.API_V1_PREFIX}/ai-assistant/query",
        headers=auth_headers,
        json={"query": "I am in week 24 and noticed vaginal bleeding"}
    )
    assert resp_bleed.status_code == 200
    assert resp_bleed.json()["safety_escalation"] is True


async def test_ai_grounded_educational_guidance(client: AsyncClient, auth_headers: dict):
    resp = await client.post(
        f"{settings.API_V1_PREFIX}/ai-assistant/query",
        headers=auth_headers,
        json={"query": "How can I improve my iron intake and avoid anemia?"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["safety_escalation"] is False
    assert len(data["citations"]) > 0
    assert "iron" in data["answer"].lower()
    assert "does not diagnose" in data["disclaimer"]


async def test_nutrition_logging_and_daily_summary(client: AsyncClient, auth_headers: dict):
    # Analyze food
    ana_resp = await client.post(
        f"{settings.API_V1_PREFIX}/nutrition/analyze?food_description=Yellow%20Moong%20Dal%20with%20Roti",
        headers=auth_headers
    )
    assert ana_resp.status_code == 200
    food_data = ana_resp.json()
    assert "Dal" in food_data["suggested_name"]
    assert food_data["is_estimate"] is True

    # Log meal
    log_resp = await client.post(
        f"{settings.API_V1_PREFIX}/nutrition/logs",
        headers=auth_headers,
        json={
            "meal_category": "lunch",
            "user_confirmed_name": "Moong Dal & 2 Rotis",
            "portion_description": "1 bowl dal, 2 rotis",
            "calories_estimate": 330.0,
            "protein_grams": 14.6,
            "carbs_grams": 58.0,
            "fat_grams": 4.3,
            "iron_mg": 4.2,
            "is_ai_identified": True
        }
    )
    assert log_resp.status_code == 201

    # Log hydration
    water_resp = await client.post(
        f"{settings.API_V1_PREFIX}/nutrition/hydration",
        headers=auth_headers,
        json={"amount_ml": 500}
    )
    assert water_resp.status_code == 201

    # Daily summary
    summary_resp = await client.get(
        f"{settings.API_V1_PREFIX}/nutrition/daily-summary",
        headers=auth_headers
    )
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert summary["total_calories_estimate"] >= 330.0
    assert summary["total_water_ml"] >= 500
    assert "statistical dietary estimates" in summary["nutritional_disclaimer"]


async def test_privacy_data_export_and_account_deletion(client: AsyncClient):
    # Create temporary user for privacy test
    await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": "privacy_user@example.com",
            "password": "SafePassword123!",
            "full_name": "Privacy User"
        }
    )
    login = await client.post(
        f"{settings.API_V1_PREFIX}/auth/login",
        json={"email": "privacy_user@example.com", "password": "SafePassword123!"}
    )
    h = {"Authorization": f"Bearer {login.json()['access_token']}"}

    # Export data
    exp_resp = await client.get(f"{settings.API_V1_PREFIX}/privacy/export", headers=h)
    assert exp_resp.status_code == 200
    assert "user_profile" in exp_resp.json()

    # Delete account
    del_resp = await client.post(
        f"{settings.API_V1_PREFIX}/privacy/delete-account",
        headers=h,
        json={"confirmation": "DELETE MY ACCOUNT"}
    )
    assert del_resp.status_code == 204

    # Verify user can no longer log in
    relogin = await client.post(
        f"{settings.API_V1_PREFIX}/auth/login",
        json={"email": "privacy_user@example.com", "password": "SafePassword123!"}
    )
    assert relogin.status_code == 401
