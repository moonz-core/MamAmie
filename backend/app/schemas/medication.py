from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class MedicationCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    dose: str = Field(..., min_length=1, max_length=64)
    unit: str = Field(..., min_length=1, max_length=64)
    schedule_type: str = Field("daily", description="daily, twice_daily, custom")
    time_minutes: Optional[int] = Field(None, ge=0, le=1439)
    instructions: Optional[str] = ""
    is_supplement: bool = False
    clinician_confirmed: bool = False


class MedicationUpdate(BaseModel):
    name: Optional[str] = None
    dose: Optional[str] = None
    unit: Optional[str] = None
    schedule_type: Optional[str] = None
    time_minutes: Optional[int] = None
    instructions: Optional[str] = None
    is_supplement: Optional[bool] = None
    clinician_confirmed: Optional[bool] = None
    is_active: Optional[bool] = None


class DoseLogCreate(BaseModel):
    medication_id: str
    scheduled_date: date
    status: str = Field("taken", description="taken, skipped, missed")


class DoseLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    medication_id: str
    user_id: str
    scheduled_date: date
    status: str
    taken_at: Optional[datetime] = None
    created_at: datetime


class MedicationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    name: str
    dose: str
    unit: str
    schedule_type: str
    time_minutes: Optional[int] = None
    instructions: str
    is_supplement: bool
    clinician_confirmed: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime
