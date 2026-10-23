from typing import Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException
from app.db.session import get_db
from app.models.user import User, UserProfile
from app.models.pregnancy import PregnancyJourney
from app.models.postpartum import PostpartumRecord
from app.schemas.postpartum import (
    PostpartumRecordCreate,
    PostpartumRecordResponse
)

router = APIRouter(prefix="/postpartum", tags=["Postpartum Recovery & Fourth Trimester"])


@router.post("/transition", response_model=PostpartumRecordResponse, status_code=status.HTTP_201_CREATED)
async def transition_to_postpartum(
    data: PostpartumRecordCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # 1. Update user profile stage to postpartum
    await db.execute(
        update(UserProfile)
        .where(UserProfile.user_id == current_user.id)
        .values(current_stage="postpartum")
    )

    # 2. Complete and archive active pregnancy journey while retaining history
    await db.execute(
        update(PregnancyJourney)
        .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
        .values(is_active=False, status="delivered", delivery_date=data.delivery_date)
    )

    # 3. Create postpartum record
    record = PostpartumRecord(
        user_id=current_user.id,
        delivery_date=data.delivery_date,
        delivery_type=data.delivery_type,
        recovery_notes=data.recovery_notes or "",
        lochia_status=data.lochia_status or "normal",
        emotional_wellbeing_notes=data.emotional_wellbeing_notes or "",
        breastfeeding_status=data.breastfeeding_status or "exclusive",
        pelvic_floor_exercises_done=data.pelvic_floor_exercises_done
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


@router.get("/", response_model=Optional[PostpartumRecordResponse])
async def get_postpartum_record(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PostpartumRecord)
        .where(PostpartumRecord.user_id == current_user.id)
        .order_by(PostpartumRecord.created_at.desc())
    )
    return result.scalar_one_or_none()


@router.put("/", response_model=PostpartumRecordResponse)
async def update_postpartum_record(
    data: PostpartumRecordCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PostpartumRecord)
        .where(PostpartumRecord.user_id == current_user.id)
        .order_by(PostpartumRecord.created_at.desc())
    )
    record = result.scalar_one_or_none()
    if not record:
        record = PostpartumRecord(user_id=current_user.id, delivery_date=data.delivery_date)
        db.add(record)

    record.delivery_type = data.delivery_type
    record.recovery_notes = data.recovery_notes or ""
    record.lochia_status = data.lochia_status or "normal"
    record.emotional_wellbeing_notes = data.emotional_wellbeing_notes or ""
    record.breastfeeding_status = data.breastfeeding_status or "exclusive"
    record.pelvic_floor_exercises_done = data.pelvic_floor_exercises_done

    await db.commit()
    await db.refresh(record)
    return record
