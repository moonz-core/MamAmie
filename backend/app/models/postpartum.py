from datetime import date
from typing import Optional
from sqlalchemy import Boolean, Date, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class PostpartumRecord(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "postpartum_records"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    delivery_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    delivery_type: Mapped[str] = mapped_column(String(64), default="vaginal", nullable=False) # vaginal, cesarean
    recovery_notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
    lochia_status: Mapped[str] = mapped_column(String(64), default="normal", nullable=False)
    emotional_wellbeing_notes: Mapped[str] = mapped_column(Text, default="", nullable=False)
    breastfeeding_status: Mapped[str] = mapped_column(String(64), default="exclusive", nullable=False)
    pelvic_floor_exercises_done: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
