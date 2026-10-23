from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, ConfigDict


class VaccinationRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    newborn_id: str
    vaccine_name: str
    due_age_weeks: int
    due_date: date
    status: str
    administered_date: Optional[date] = None
    administered_by: str
    batch_number: Optional[str] = None
    notes: str
    created_at: datetime


class VaccinationRecordUpdate(BaseModel):
    status: str = Field(..., description="scheduled, completed, delayed")
    administered_date: Optional[date] = None
    administered_by: Optional[str] = None
    batch_number: Optional[str] = None
    notes: Optional[str] = None


class NewbornProfileCreate(BaseModel):
    baby_name: str = Field(..., min_length=1, max_length=255)
    birth_date: date
    gender: str = "unspecified"
    birth_weight_grams: Optional[int] = None
    pediatrician_name: Optional[str] = ""
    notes: Optional[str] = ""


class NewbornProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    parent_user_id: str
    baby_name: str
    birth_date: date
    gender: str
    birth_weight_grams: Optional[int] = None
    pediatrician_name: str
    notes: str
    vaccinations: List[VaccinationRecordResponse] = []
    created_at: datetime
    updated_at: datetime


class CaregiverAuthorizationCreate(BaseModel):
    caregiver_email: EmailStr
    newborn_id: str
    permission_level: str = "viewer"


class CaregiverAuthorizationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    parent_user_id: str
    caregiver_email: str
    newborn_id: str
    permission_level: str
    is_active: bool
    created_at: datetime
