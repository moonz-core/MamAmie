from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class PlannerEntryCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    category: str = Field(..., description="appointment, medicalRecord, symptom, food, journal, milestone, task, medication")
    day_key: str = Field(..., pattern=r"^\d{4}-\d{2}-\d{2}$", description="YYYY-MM-DD")
    time_minutes: Optional[int] = Field(None, ge=0, le=1439, description="Minutes after midnight")
    notes: Optional[str] = ""
    is_completed: bool = False
    extra_data: Optional[Dict[str, Any]] = None


class PlannerEntryUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    category: Optional[str] = None
    day_key: Optional[str] = Field(None, pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_minutes: Optional[int] = Field(None, ge=0, le=1439)
    notes: Optional[str] = None
    is_completed: Optional[bool] = None
    extra_data: Optional[Dict[str, Any]] = None


class PlannerEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    title: str
    category: str
    day_key: str
    time_minutes: Optional[int] = None
    notes: str
    is_completed: bool
    extra_data: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
