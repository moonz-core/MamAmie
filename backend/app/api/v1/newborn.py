from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.db.session import get_db
from app.models.user import User
from app.models.newborn import NewbornProfile, VaccinationRecord, CaregiverAuthorization
from app.schemas.newborn import (
    NewbornProfileCreate,
    NewbornProfileResponse,
    VaccinationRecordResponse,
    VaccinationRecordUpdate,
    CaregiverAuthorizationCreate,
    CaregiverAuthorizationResponse
)
from app.services.vaccination_scheduler import VaccinationSchedulerService

router = APIRouter(prefix="/newborn", tags=["Newborn Care & Pediatric Tracking"])


@router.post("/profiles", response_model=NewbornProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_newborn_profile(
    data: NewbornProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    profile = NewbornProfile(
        parent_user_id=current_user.id,
        baby_name=data.baby_name.strip(),
        birth_date=data.birth_date,
        gender=data.gender,
        birth_weight_grams=data.birth_weight_grams,
        pediatrician_name=data.pediatrician_name or "",
        notes=data.notes or ""
    )
    db.add(profile)
    await db.flush()

    # Automatically generate standard Indian UIP vaccination schedule
    schedule_items = VaccinationSchedulerService.generate_schedule(data.birth_date)
    for item in schedule_items:
        v = VaccinationRecord(
            newborn_id=profile.id,
            vaccine_name=item["vaccine_name"],
            due_age_weeks=item["due_age_weeks"],
            due_date=item["due_date"],
            status="scheduled",
            notes=item["notes"]
        )
        db.add(v)

    await db.commit()
    await db.refresh(profile)

    # Reload with vaccinations eagerly loaded
    result = await db.execute(
        select(NewbornProfile)
        .options(selectinload(NewbornProfile.vaccinations))
        .where(NewbornProfile.id == profile.id)
    )
    return result.scalar_one()


@router.get("/profiles", response_model=List[NewbornProfileResponse])
async def list_newborn_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(NewbornProfile)
        .options(selectinload(NewbornProfile.vaccinations))
        .where(NewbornProfile.parent_user_id == current_user.id)
        .order_by(NewbornProfile.birth_date.desc())
    )
    return result.scalars().all()


@router.get("/profiles/{profile_id}", response_model=NewbornProfileResponse)
async def get_newborn_profile(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(NewbornProfile)
        .options(selectinload(NewbornProfile.vaccinations))
        .where(NewbornProfile.id == profile_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise NotFoundException("Newborn profile not found")

    # Check parent ownership or authorized caregiver
    if profile.parent_user_id != current_user.id:
        caregiver_res = await db.execute(
            select(CaregiverAuthorization).where(
                CaregiverAuthorization.newborn_id == profile_id,
                CaregiverAuthorization.caregiver_email == current_user.email,
                CaregiverAuthorization.is_active == True
            )
        )
        if not caregiver_res.scalar_one_or_none():
            raise ForbiddenException("Access denied to newborn health records")

    return profile


@router.put("/vaccinations/{vaccine_id}", response_model=VaccinationRecordResponse)
async def update_vaccination(
    vaccine_id: str,
    data: VaccinationRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(VaccinationRecord)
        .join(NewbornProfile)
        .where(VaccinationRecord.id == vaccine_id)
    )
    vaccine = result.scalar_one_or_none()
    if not vaccine:
        raise NotFoundException("Vaccination record not found")

    newborn_res = await db.execute(select(NewbornProfile).where(NewbornProfile.id == vaccine.newborn_id))
    newborn = newborn_res.scalar_one()

    if newborn.parent_user_id != current_user.id:
        raise ForbiddenException("Only the parent or authorized caregiver can update vaccinations")

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(vaccine, field, value)

    await db.commit()
    await db.refresh(vaccine)
    return vaccine


@router.post("/caregivers", response_model=CaregiverAuthorizationResponse, status_code=status.HTTP_201_CREATED)
async def authorize_caregiver(
    data: CaregiverAuthorizationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    newborn_res = await db.execute(
        select(NewbornProfile).where(
            NewbornProfile.id == data.newborn_id,
            NewbornProfile.parent_user_id == current_user.id
        )
    )
    if not newborn_res.scalar_one_or_none():
        raise ForbiddenException("You can only authorize caregivers for your own registered newborn")

    auth = CaregiverAuthorization(
        parent_user_id=current_user.id,
        caregiver_email=data.caregiver_email.lower(),
        newborn_id=data.newborn_id,
        permission_level=data.permission_level,
        is_active=True
    )
    db.add(auth)
    await db.commit()
    await db.refresh(auth)
    return auth
