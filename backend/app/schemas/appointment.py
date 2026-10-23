from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class AppointmentCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    clinician_or_clinic: str = Field("", max_length=255)
    location: str = Field("", max_length=255)
    scheduled_date: date
    scheduled_time_minutes: Optional[int] = Field(None, ge=0, le=1439)
    questions: Optional[str] = ""
    status: str = Field("planned", description="planned, completed, cancelled")
    follow_up_instructions: Optional[str] = None
    notes: Optional[str] = ""


class AppointmentUpdate(BaseModel):
    title: Optional[str] = None
    clinician_or_clinic: Optional[str] = None
    location: Optional[str] = None
    scheduled_date: Optional[date] = None
    scheduled_time_minutes: Optional[int] = None
    questions: Optional[str] = None
    status: Optional[str] = None
    follow_up_instructions: Optional[str] = None
    notes: Optional[str] = None


class AppointmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    title: str
    clinician_or_clinic: str
    location: str
    scheduled_date: date
    scheduled_time_minutes: Optional[int] = None
    questions: str
    status: str
    follow_up_instructions: Optional[str] = None
    notes: str
    created_at: datetime
    updated_at: datetime
