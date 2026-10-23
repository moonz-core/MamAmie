from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.db.session import get_db
from app.models.user import User
from app.models.appointment import Appointment
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse
)

router = APIRouter(prefix="/appointments", tags=["Appointments & Medical Follow-ups"])


@router.get("/", response_model=List[AppointmentResponse])
async def list_appointments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Appointment)
        .where(Appointment.user_id == current_user.id)
        .order_by(Appointment.scheduled_date.asc())
    )
    return result.scalars().all()


@router.post("/", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    data: AppointmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    appointment = Appointment(
        user_id=current_user.id,
        title=data.title,
        clinician_or_clinic=data.clinician_or_clinic,
        location=data.location,
        scheduled_date=data.scheduled_date,
        scheduled_time_minutes=data.scheduled_time_minutes,
        questions=data.questions or "",
        status=data.status,
        follow_up_instructions=data.follow_up_instructions,
        notes=data.notes or ""
    )
    db.add(appointment)
    await db.commit()
    await db.refresh(appointment)
    return appointment


@router.get("/{appointment_id}", response_model=AppointmentResponse)
async def get_appointment(
    appointment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Appointment).where(Appointment.id == appointment_id))
    appointment = result.scalar_one_or_none()
    if not appointment:
        raise NotFoundException("Appointment not found")

    if appointment.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested appointment")

    return appointment


@router.put("/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: str,
    data: AppointmentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Appointment).where(Appointment.id == appointment_id))
    appointment = result.scalar_one_or_none()
    if not appointment:
        raise NotFoundException("Appointment not found")

    if appointment.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested appointment")

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(appointment, field, value)

    await db.commit()
    await db.refresh(appointment)
    return appointment


@router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_appointment(
    appointment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Appointment).where(Appointment.id == appointment_id))
    appointment = result.scalar_one_or_none()
    if not appointment:
        raise NotFoundException("Appointment not found")

    if appointment.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested appointment")

    await db.delete(appointment)
    await db.commit()
