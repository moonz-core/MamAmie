import uuid
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.exceptions import ConflictException, UnauthorizedException, NotFoundException
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token, decode_token
from app.db.session import get_db
from app.models.user import User, UserProfile, RefreshToken
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    UserResponse,
    PasswordResetRequest,
    PasswordResetConfirmRequest
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    data: UserRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    # Check if user already exists
    existing = await db.execute(select(User).where(User.email == data.email.lower()))
    if existing.scalar_one_or_none():
        raise ConflictException("An account with this email address already exists")

    hashed_pw = get_password_hash(data.password)
    user = User(
        email=data.email.lower(),
        hashed_password=hashed_pw,
        full_name=data.full_name.strip(),
        phone_number=data.phone_number,
        is_active=True,
        is_verified=False,
        role="user"
    )
    db.add(user)
    await db.flush()

    # Create associated default profile
    profile = UserProfile(
        user_id=user.id,
        current_stage="pregnant",
        language_code="en",
        timezone="Asia/Kolkata",
        is_onboarding_completed=False
    )
    db.add(profile)
    await db.commit()
    await db.refresh(user)

    return user


@router.post("/login", response_model=TokenResponse)
async def login(
    data: UserLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(User).where(User.email == data.email.lower()))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.hashed_password):
        raise UnauthorizedException("Invalid email address or password")

    if not user.is_active:
        raise UnauthorizedException("Account is deactivated")

    # Issue tokens
    token_jti = uuid.uuid4().hex
    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id, token_id=token_jti)

    # Store refresh token record for revocation tracking
    now = datetime.now(timezone.utc)
    rt_record = RefreshToken(
        user_id=user.id,
        token_jti=token_jti,
        expires_at=now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        is_revoked=False
    )
    db.add(rt_record)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    payload = decode_token(data.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException("Invalid refresh token")

    user_id = payload.get("sub")
    token_jti = payload.get("jti")

    if not user_id or not token_jti:
        raise UnauthorizedException("Malformed refresh token")

    # Check token revocation
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_jti == token_jti,
            RefreshToken.user_id == user_id
        )
    )
    rt = result.scalar_one_or_none()

    if not rt or rt.is_revoked:
        raise UnauthorizedException("Refresh token has been revoked or expired")

    # Revoke current refresh token and issue new pair (rotation)
    rt.is_revoked = True
    new_jti = uuid.uuid4().hex
    new_access = create_access_token(subject=user_id)
    new_refresh = create_refresh_token(subject=user_id, token_id=new_jti)

    new_rt = RefreshToken(
        user_id=user_id,
        token_jti=new_jti,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        is_revoked=False
    )
    db.add(new_rt)
    await db.commit()

    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    data: RefreshTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    payload = decode_token(data.refresh_token)
    if payload and payload.get("jti"):
        token_jti = payload["jti"]
        await db.execute(
            update(RefreshToken)
            .where(RefreshToken.token_jti == token_jti, RefreshToken.user_id == current_user.id)
            .values(is_revoked=True)
        )
        await db.commit()


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
