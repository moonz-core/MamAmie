import uuid
import pytest
from httpx import AsyncClient
from app.core.config import settings

pytestmark = pytest.mark.asyncio


async def test_user_registration(client: AsyncClient):
    unique_email = f"ananya_{uuid.uuid4().hex[:6]}@example.com"
    resp = await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": unique_email,
            "password": "StrongPassword99!",
            "full_name": "Ananya Roy",
            "phone_number": "+919988776655"
        }
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == unique_email
    assert data["full_name"] == "Ananya Roy"
    assert "hashed_password" not in data


async def test_duplicate_registration_rejected(client: AsyncClient):
    unique_email = f"dup_{uuid.uuid4().hex[:6]}@example.com"
    # First registration
    await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": unique_email,
            "password": "StrongPassword99!",
            "full_name": "Original"
        }
    )
    # Second registration with same email
    resp = await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": unique_email,
            "password": "StrongPassword99!",
            "full_name": "Duplicate"
        }
    )
    assert resp.status_code == 409


async def test_user_login_and_token_refresh(client: AsyncClient):
    unique_email = f"login_{uuid.uuid4().hex[:6]}@example.com"
    # Register
    await client.post(
        f"{settings.API_V1_PREFIX}/auth/register",
        json={
            "email": unique_email,
            "password": "StrongPassword99!",
            "full_name": "Login User"
        }
    )

    # Login
    login_resp = await client.post(
        f"{settings.API_V1_PREFIX}/auth/login",
        json={
            "email": unique_email,
            "password": "StrongPassword99!"
        }
    )
    assert login_resp.status_code == 200
    token_data = login_resp.json()
    assert "access_token" in token_data
    assert "refresh_token" in token_data

    # Use access token to fetch /me
    headers = {"Authorization": f"Bearer {token_data['access_token']}"}
    me_resp = await client.get(f"{settings.API_V1_PREFIX}/auth/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == unique_email

    # Refresh token rotation
    ref_resp = await client.post(
        f"{settings.API_V1_PREFIX}/auth/refresh",
        json={"refresh_token": token_data["refresh_token"]}
    )
    assert ref_resp.status_code == 200
    new_token_data = ref_resp.json()
    assert "access_token" in new_token_data
    assert new_token_data["refresh_token"] != token_data["refresh_token"]
