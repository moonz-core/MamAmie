from datetime import date, datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class UserProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    current_stage: str # planning, pregnant, postpartum
    language_code: str
    timezone: str
    diet_preferences: Optional[Dict[str, Any]] = None
    food_allergies: Optional[List[str]] = None
    notification_preferences: Optional[Dict[str, Any]] = None
    clinician_notes: Optional[str] = None
    is_onboarding_completed: bool
    created_at: datetime
    updated_at: datetime


class UserProfileUpdateRequest(BaseModel):
    current_stage: Optional[str] = None
    language_code: Optional[str] = None
    timezone: Optional[str] = None
    diet_preferences: Optional[Dict[str, Any]] = None
    food_allergies: Optional[List[str]] = None
    notification_preferences: Optional[Dict[str, Any]] = None
    clinician_notes: Optional[str] = None


class OnboardingSetupRequest(BaseModel):
    current_stage: str = Field(..., description="'planning', 'pregnant', or 'postpartum'")
    lmp_date: Optional[date] = Field(None, description="Last menstrual period date (for pregnancy)")
    edd_date: Optional[date] = Field(None, description="Clinician estimated due date")
    delivery_date: Optional[date] = Field(None, description="Childbirth delivery date (for postpartum)")
    diet_preferences: Optional[Dict[str, Any]] = None
    food_allergies: Optional[List[str]] = None
    consent_health_data: bool = Field(True, description="Explicit consent for processing maternal health metrics")


class ConsentRequest(BaseModel):
    consent_type: str = Field(..., description="e.g. 'health_data_processing', 'ai_assistant', 'terms'")
    granted: bool = True
    notes: Optional[str] = None


class ConsentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    consent_type: str
    granted: bool
    created_at: datetime
