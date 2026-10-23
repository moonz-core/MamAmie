import pytest
from httpx import AsyncClient
from app.core.config import settings

pytestmark = pytest.mark.asyncio


async def test_planner_crud_and_cross_user_isolation(client: AsyncClient, auth_headers: dict):
    # 1. User A creates a planner entry
    create_resp = await client.post(
        f"{settings.API_V1_PREFIX}/planner/",
        headers=auth_headers,
        json={
            "title": "Prenatal Ultrasound Check",
            "category": "appointment",
            "day_key": "2026-10-25",
            "time_minutes": 600,
            "notes": "Bring previous scan reports and hospital file"
        }
    )
    assert create_resp.status_code == 201
    entry_id = create_resp.json()["id"]

    # 2. User A can retrieve it
    get_resp = await client.get(f"{settings.API_V1_PREFIX}/planner/{entry_id}", headers=auth_headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["title"] == "Prenatal Ultrasound Check"

    # 3. Create a second independent user (User B)
    await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": "userb@example.com",
            "password": "Password123!456",
            "full_name": "User B"
        }
    )
    login_b = await client.post(
        f"{settings.API_V1_PREFIX}/auth/login",
        json={"email": "userb@example.com", "password": "Password123!456"}
    )
    headers_b = {"Authorization": f"Bearer {login_b.json()['access_token']}"}

    # 4. User B attempts to access User A's health record -> MUST return 403 Forbidden
    cross_access_resp = await client.get(f"{settings.API_V1_PREFIX}/planner/{entry_id}", headers=headers_b)
    assert cross_access_resp.status_code == 403

    # 5. User B attempts to delete User A's record -> MUST return 403 Forbidden
    cross_delete_resp = await client.delete(f"{settings.API_V1_PREFIX}/planner/{entry_id}", headers=headers_b)
    assert cross_delete_resp.status_code == 403
