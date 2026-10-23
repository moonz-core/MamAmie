from datetime import date
from typing import Optional
from sqlalchemy import Date, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class Appointment(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "appointments"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    clinician_or_clinic: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    location: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    scheduled_time_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    questions: Mapped[str] = mapped_column(Text, default="", nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="planned", nullable=False) # planned, completed, cancelled
    follow_up_instructions: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
