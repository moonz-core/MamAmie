from datetime import date, datetime
from typing import Optional, List
from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, UUIDMixin, TimestampMixin


class Medication(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "medications"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    dose: Mapped[str] = mapped_column(String(64), nullable=False)
    unit: Mapped[str] = mapped_column(String(64), nullable=False)
    schedule_type: Mapped[str] = mapped_column(String(64), default="daily", nullable=False)
    time_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    instructions: Mapped[str] = mapped_column(Text, default="", nullable=False)
    is_supplement: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    clinician_confirmed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)

    dose_logs: Mapped[List["DoseLog"]] = relationship("DoseLog", back_populates="medication", cascade="all, delete-orphan")


class DoseLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "dose_logs"

    medication_id: Mapped[str] = mapped_column(String(36), ForeignKey("medications.id", ondelete="CASCADE"), index=True, nullable=False)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="taken", nullable=False) # taken, skipped, missed
    taken_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    medication: Mapped["Medication"] = relationship("Medication", back_populates="dose_logs")
