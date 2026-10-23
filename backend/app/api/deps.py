from typing import Optional
from fastapi import Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.exceptions import UnauthorizedException, ForbiddenException
from app.core.security import decode_token
from app.db.session import get_db
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_PREFIX}/auth/login"
)


async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> User:
    payload = decode_token(token)
    if not payload:
        raise UnauthorizedException("Invalid or expired authentication token")

    token_type = payload.get("type")
    if token_type != "access":
        raise UnauthorizedException("Invalid token type")

    user_id: Optional[str] = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Token payload missing subject identifier")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedException("User account associated with this token no longer exists")

    if not user.is_active:
        raise ForbiddenException("User account is disabled or deactivated")

    return user


async def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    if current_user.role != "admin":
        raise ForbiddenException("Administrative privileges required")
    return current_user
