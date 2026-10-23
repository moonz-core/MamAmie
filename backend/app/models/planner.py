from typing import Optional
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text, JSON, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class PlannerEntry(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "planner_entries"
    __table_args__ = (
        Index("ix_planner_user_day", "user_id", "day_key"),
    )

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(64), index=True, nullable=False) # appointment, medicalRecord, symptom, food, journal, milestone, task, medication
    day_key: Mapped[str] = mapped_column(String(10), index=True, nullable=False) # YYYY-MM-DD
    time_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True) # minutes after midnight
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, index=True, nullable=False)
    
    # Structured category details payload matching CalendarEntry.swift
    extra_data: Mapped[Optional[dict]] = mapped_column(JSON, default=dict, nullable=True)
