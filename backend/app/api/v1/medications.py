from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.db.session import get_db
from app.models.user import User
from app.models.medication import Medication, DoseLog
from app.schemas.medication import (
    MedicationCreate,
    MedicationUpdate,
    MedicationResponse,
    DoseLogCreate,
    DoseLogResponse
)

router = APIRouter(prefix="/medications", tags=["Medicine & Supplement Reminders"])


@router.get("/", response_model=List[MedicationResponse])
async def list_medications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Medication)
        .where(Medication.user_id == current_user.id, Medication.is_active == True)
        .order_by(Medication.time_minutes.asc().nullsfirst())
    )
    return result.scalars().all()


@router.post("/", response_model=MedicationResponse, status_code=status.HTTP_201_CREATED)
async def create_medication(
    data: MedicationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    medication = Medication(
        user_id=current_user.id,
        name=data.name.strip(),
        dose=data.dose.strip(),
        unit=data.unit.strip(),
        schedule_type=data.schedule_type,
        time_minutes=data.time_minutes,
        instructions=data.instructions or "",
        is_supplement=data.is_supplement,
        clinician_confirmed=data.clinician_confirmed,
        is_active=True
    )
    db.add(medication)
    await db.commit()
    await db.refresh(medication)
    return medication


@router.put("/{medication_id}", response_model=MedicationResponse)
async def update_medication(
    medication_id: str,
    data: MedicationUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Medication).where(Medication.id == medication_id))
    medication = result.scalar_one_or_none()
    if not medication:
        raise NotFoundException("Medication schedule not found")

    if medication.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested medication")

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(medication, field, value)

    await db.commit()
    await db.refresh(medication)
    return medication


@router.delete("/{medication_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medication(
    medication_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Medication).where(Medication.id == medication_id))
    medication = result.scalar_one_or_none()
    if not medication:
        raise NotFoundException("Medication schedule not found")

    if medication.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested medication")

    medication.is_active = False
    await db.commit()


@router.post("/doses", response_model=DoseLogResponse, status_code=status.HTTP_201_CREATED)
async def log_dose(
    data: DoseLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Medication).where(Medication.id == data.medication_id))
    medication = result.scalar_one_or_none()
    if not medication or medication.user_id != current_user.id:
        raise NotFoundException("Medication not found")

    log = DoseLog(
        medication_id=data.medication_id,
        user_id=current_user.id,
        scheduled_date=data.scheduled_date,
        status=data.status,
        taken_at=datetime.now(timezone.utc) if data.status == "taken" else None
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


@router.get("/doses/history", response_model=List[DoseLogResponse])
async def get_dose_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(DoseLog)
        .where(DoseLog.user_id == current_user.id)
        .order_by(DoseLog.scheduled_date.desc(), DoseLog.created_at.desc())
        .limit(50)
    )
    return result.scalars().all()
