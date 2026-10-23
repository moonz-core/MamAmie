from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException
from app.db.session import get_db
from app.models.user import User
from app.models.pregnancy import PregnancyJourney, PregnancyMilestone
from app.schemas.pregnancy import (
    PregnancyJourneyCreate,
    PregnancyJourneyResponse,
    PregnancyCalculationResponse,
    PregnancyMilestoneResponse
)
from app.services.pregnancy_calculator import PregnancyCalculatorService

router = APIRouter(prefix="/pregnancy", tags=["Pregnancy Timeline & Planner"])


@router.get("/current", response_model=Optional[PregnancyJourneyResponse])
async def get_current_pregnancy(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PregnancyJourney)
        .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
        .order_by(PregnancyJourney.created_at.desc())
    )
    journey = result.scalar_one_or_none()
    return journey


@router.post("/", response_model=PregnancyJourneyResponse, status_code=status.HTTP_201_CREATED)
async def create_or_update_pregnancy(
    data: PregnancyJourneyCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Archive any previous active journeys
    await db.execute(
        update(PregnancyJourney)
        .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
        .values(is_active=False)
    )

    journey = PregnancyJourney(
        user_id=current_user.id,
        lmp_date=data.lmp_date,
        edd_date=data.edd_date,
        is_active=True,
        status="active",
        birth_notes=data.birth_notes
    )
    db.add(journey)
    await db.flush()

    # Generate standard pregnancy milestones
    milestones_data = [
        (8, "First Prenatal Ultrasound / Dating Scan"),
        (12, "End of 1st Trimester & NT Scan Window"),
        (16, "Early 2nd Trimester Wellness Check"),
        (20, "Level II / Anomaly Scan (Mid-pregnancy ultrasound)"),
        (24, "Glucose Tolerance Test (GDM screening)"),
        (28, "Start of 3rd Trimester & Growth Scan"),
        (32, "Birth Plan Preparation & Third Trimester Check"),
        (36, "Weekly Monitoring & Hospital Bag Check"),
        (40, "Estimated Due Date Arrival"),
    ]
    for week_num, title in milestones_data:
        m = PregnancyMilestone(
            journey_id=journey.id,
            week_number=week_num,
            title=title,
            is_completed=False
        )
        db.add(m)

    await db.commit()
    await db.refresh(journey)
    return journey


@router.get("/calculations", response_model=PregnancyCalculationResponse)
async def get_pregnancy_calculations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PregnancyJourney)
        .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
        .order_by(PregnancyJourney.created_at.desc())
    )
    journey = result.scalar_one_or_none()

    lmp = journey.lmp_date if journey else None
    edd = journey.edd_date if journey else None

    return PregnancyCalculatorService.calculate_from_lmp_or_edd(lmp_date=lmp, edd_date=edd)


@router.get("/milestones", response_model=List[PregnancyMilestoneResponse])
async def list_milestones(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PregnancyJourney)
        .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
    )
    journey = result.scalar_one_or_none()
    if not journey:
        return []

    milestones_res = await db.execute(
        select(PregnancyMilestone)
        .where(PregnancyMilestone.journey_id == journey.id)
        .order_by(PregnancyMilestone.week_number.asc())
    )
    return milestones_res.scalars().all()
