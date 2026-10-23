from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.db.session import get_db
from app.models.user import User
from app.models.planner import PlannerEntry
from app.schemas.planner import (
    PlannerEntryCreate,
    PlannerEntryUpdate,
    PlannerEntryResponse
)

router = APIRouter(prefix="/planner", tags=["Planner & Calendar Journal"])


@router.get("/", response_model=List[PlannerEntryResponse])
async def list_planner_entries(
    day_key: Optional[str] = Query(None, description="Filter by YYYY-MM-DD"),
    category: Optional[str] = Query(None, description="Filter by category"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(PlannerEntry).where(PlannerEntry.user_id == current_user.id)
    if day_key:
        query = query.where(PlannerEntry.day_key == day_key)
    if category:
        query = query.where(PlannerEntry.category == category)

    query = query.order_by(PlannerEntry.day_key.asc(), PlannerEntry.time_minutes.asc().nullsfirst())
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/", response_model=PlannerEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_planner_entry(
    data: PlannerEntryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    entry = PlannerEntry(
        user_id=current_user.id,
        title=data.title,
        category=data.category,
        day_key=data.day_key,
        time_minutes=data.time_minutes,
        notes=data.notes or "",
        is_completed=data.is_completed,
        extra_data=data.extra_data or {}
    )
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return entry


@router.get("/{entry_id}", response_model=PlannerEntryResponse)
async def get_planner_entry(
    entry_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PlannerEntry).where(PlannerEntry.id == entry_id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise NotFoundException("Planner entry not found")

    # Object-level authorization check
    if entry.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested entry")

    return entry


@router.put("/{entry_id}", response_model=PlannerEntryResponse)
async def update_planner_entry(
    entry_id: str,
    data: PlannerEntryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(PlannerEntry).where(PlannerEntry.id == entry_id))
    entry = result.scalar_one_or_none()
    if not entry:
        raise NotFoundException("Planner entry not found")

    if entry.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested entry")

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(entry, field, value)

    await db.commit()
    await db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_planner_entry(
    entry_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(PlannerEntry).where(PlannerEntry.id == entry_id))
    entry = result.scalar_one_or_none()
    if not entry:
        raise NotFoundException("Planner entry not found")

    if entry.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested entry")

    await db.delete(entry)
    await db.commit()
