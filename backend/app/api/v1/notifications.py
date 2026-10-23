from typing import Dict, Any, List
from fastapi import APIRouter, Depends, Body
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User, UserProfile
from app.models.notification import NotificationRecord

router = APIRouter(prefix="/notifications", tags=["Notifications & Reminders"])


@router.get("/preferences")
async def get_notification_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    default_prefs = {
        "appointments_enabled": True,
        "medications_enabled": True,
        "hydration_reminders": True,
        "quiet_hours_start": 22,
        "quiet_hours_end": 7
    }
    if profile and profile.notification_preferences:
        return {**default_prefs, **profile.notification_preferences}
    return default_prefs


@router.put("/preferences")
async def update_notification_preferences(
    preferences: Dict[str, Any] = Body(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if profile:
        profile.notification_preferences = preferences
        await db.commit()
    return preferences


@router.get("/history")
async def get_notification_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(NotificationRecord)
        .where(NotificationRecord.user_id == current_user.id)
        .order_by(NotificationRecord.scheduled_for.desc())
        .limit(20)
    )
    records = result.scalars().all()
    return records
