from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class EducationalArticleCreate(BaseModel):
    stage: str = Field(..., description="planning, pregnant, postpartum, newborn")
    target_week: Optional[int] = Field(None, ge=1, le=42)
    category: str = Field(..., description="fetal_development, nutrition, warning_signs, wellness, labor_prep, breastfeeding")
    title: str = Field(..., min_length=3, max_length=255)
    summary: str
    content: str
    source_attribution: str = "WHO & FOGSI Clinical Guidelines"
    is_medically_reviewed: bool = True
    review_date: Optional[date] = None
    reviewer_name: Optional[str] = None
    language: str = "en"


class EducationalArticleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    stage: str
    target_week: Optional[int] = None
    category: str
    title: str
    summary: str
    content: str
    source_attribution: str
    is_medically_reviewed: bool
    review_date: Optional[date] = None
    reviewer_name: Optional[str] = None
    version: int
    is_published: bool
    language: str
    created_at: datetime
    updated_at: datetime
