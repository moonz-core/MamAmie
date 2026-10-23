from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class PregnancyJourneyCreate(BaseModel):
    lmp_date: Optional[date] = None
    edd_date: Optional[date] = None
    birth_notes: Optional[str] = None


class PregnancyMilestoneResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    week_number: int
    title: str
    description: Optional[str] = None
    is_completed: bool
    completed_at: Optional[datetime] = None


class PregnancyJourneyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    lmp_date: Optional[date] = None
    edd_date: Optional[date] = None
    is_active: bool
    status: str
    delivery_date: Optional[date] = None
    birth_notes: Optional[str] = None
    milestones: List[PregnancyMilestoneResponse] = []
    created_at: datetime
    updated_at: datetime


class PregnancyCalculationResponse(BaseModel):
    gestational_weeks: int = Field(..., description="Completed gestational weeks (0-42)")
    gestational_days: int = Field(..., description="Days into current gestational week (0-6)")
    trimester: int = Field(..., description="1, 2, or 3")
    estimated_due_date: Optional[date] = None
    days_until_due_date: Optional[int] = None
    progress_percentage: float = Field(..., description="0.0 to 100.0% completion")
    fetal_size_comparison: str = Field(..., description="Fruit or everyday object comparison")
    fetal_weight_estimate: str
    fetal_length_estimate: str
    common_symptoms: List[str]
    is_date_estimated: bool
