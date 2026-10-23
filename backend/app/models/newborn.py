from datetime import date
from typing import Optional, List
from sqlalchemy import Boolean, Date, ForeignKey, Integer, String, Text, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, UUIDMixin, TimestampMixin


class NewbornProfile(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "newborn_profiles"

    parent_user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    baby_name: Mapped[str] = mapped_column(String(255), nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    gender: Mapped[str] = mapped_column(String(32), default="unspecified", nullable=False)
    birth_weight_grams: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pediatrician_name: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)

    vaccinations: Mapped[List["VaccinationRecord"]] = relationship("VaccinationRecord", back_populates="newborn", cascade="all, delete-orphan")


class VaccinationRecord(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "vaccination_records"
    __table_args__ = (
        Index("ix_vaccination_newborn_status", "newborn_id", "status"),
    )

    newborn_id: Mapped[str] = mapped_column(String(36), ForeignKey("newborn_profiles.id", ondelete="CASCADE"), index=True, nullable=False)
    vaccine_name: Mapped[str] = mapped_column(String(255), nullable=False)
    due_age_weeks: Mapped[int] = mapped_column(Integer, nullable=False) # e.g. 0, 6, 10, 14, 24, 36
    due_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="scheduled", nullable=False) # scheduled, completed, delayed
    administered_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    administered_by: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    batch_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="", nullable=False)

    newborn: Mapped["NewbornProfile"] = relationship("NewbornProfile", back_populates="vaccinations")


class CaregiverAuthorization(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "caregiver_authorizations"

    parent_user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    caregiver_email: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    newborn_id: Mapped[str] = mapped_column(String(36), ForeignKey("newborn_profiles.id", ondelete="CASCADE"), index=True, nullable=False)
    permission_level: Mapped[str] = mapped_column(String(32), default="viewer", nullable=False) # viewer, editor
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
