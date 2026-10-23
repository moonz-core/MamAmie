from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class MedicalRecordCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    report_type: str = Field("General Report", max_length=128)
    report_date: date
    clinician_name: Optional[str] = ""
    notes: Optional[str] = ""
    follow_up_date: Optional[date] = None


class MedicalRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    title: str
    file_name: str
    file_size_bytes: int
    mime_type: str
    report_type: str
    report_date: date
    clinician_name: str
    notes: str
    ai_summary: Optional[str] = None
    follow_up_date: Optional[date] = None
    created_at: datetime
    updated_at: datetime


class SecureDownloadUrlResponse(BaseModel):
    download_url: str
    expires_in_seconds: int
