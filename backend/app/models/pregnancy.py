from datetime import date, datetime
from typing import Optional, List
from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, UUIDMixin, TimestampMixin


class PregnancyJourney(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "pregnancy_journeys"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    lmp_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    edd_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="active", nullable=False) # active, delivered, archived
    delivery_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    birth_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    milestones: Mapped[List["PregnancyMilestone"]] = relationship("PregnancyMilestone", back_populates="journey", cascade="all, delete-orphan")


class PregnancyMilestone(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "pregnancy_milestones"

    journey_id: Mapped[str] = mapped_column(String(36), ForeignKey("pregnancy_journeys.id", ondelete="CASCADE"), index=True, nullable=False)
    week_number: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    journey: Mapped["PregnancyJourney"] = relationship("PregnancyJourney", back_populates="milestones")
