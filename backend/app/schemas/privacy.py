from datetime import datetime
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class DeleteAccountRequest(BaseModel):
    confirmation: str = Field(..., description="Must be 'DELETE MY ACCOUNT' to prevent accidental erasure")


class PrivacySettingsResponse(BaseModel):
    user_id: str
    active_consents: List[str]
    last_consent_date: Optional[datetime] = None
    data_retention_policy: str = "User health records are retained until explicit account deletion request."


class DataExportResponse(BaseModel):
    export_timestamp: datetime
    user_profile: Dict[str, Any]
    pregnancy_history: List[Dict[str, Any]]
    planner_entries: List[Dict[str, Any]]
    appointments: List[Dict[str, Any]]
    medications: List[Dict[str, Any]]
    nutrition_logs: List[Dict[str, Any]]
    medical_records_metadata: List[Dict[str, Any]]
    newborn_records: List[Dict[str, Any]]
