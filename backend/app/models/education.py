from datetime import date
from typing import Optional
from sqlalchemy import Boolean, Date, Integer, String, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class EducationalArticle(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "educational_articles"
    __table_args__ = (
        Index("ix_educational_stage_week", "stage", "target_week"),
    )

    stage: Mapped[str] = mapped_column(String(32), index=True, nullable=False) # planning, pregnant, postpartum, newborn
    target_week: Mapped[Optional[int]] = mapped_column(Integer, index=True, nullable=True) # week 1 to 42
    category: Mapped[str] = mapped_column(String(64), index=True, nullable=False) # fetal_development, nutrition, warning_signs, wellness, labor_prep, breastfeeding
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False) # Markdown
    source_attribution: Mapped[str] = mapped_column(String(255), default="WHO & FOGSI Clinical Guidelines", nullable=False)
    is_medically_reviewed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    review_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    reviewer_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
    language: Mapped[str] = mapped_column(String(10), default="en", index=True, nullable=False)
