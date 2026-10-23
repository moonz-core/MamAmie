from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class FoodLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "food_logs"
    __table_args__ = (
        Index("ix_food_logs_user_date", "user_id", "logged_at"),
    )

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    meal_category: Mapped[str] = mapped_column(String(32), default="lunch", nullable=False) # breakfast, lunch, dinner, snack, other
    image_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    ai_suggested_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    user_confirmed_name: Mapped[str] = mapped_column(String(255), nullable=False)
    portion_description: Mapped[str] = mapped_column(String(128), default="1 medium serving", nullable=False)
    ingredients: Mapped[str] = mapped_column(Text, default="", nullable=False)

    # Nutritional estimates (explicitly documented as estimates, not lab tests)
    calories_estimate: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    protein_grams: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    carbs_grams: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    fat_grams: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    iron_mg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    folate_mcg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    calcium_mg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    is_ai_identified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True, nullable=False)


class HydrationLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "hydration_logs"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    amount_ml: Mapped[int] = mapped_column(Integer, default=250, nullable=False) # e.g. 250ml per glass
    logged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True, nullable=False)
