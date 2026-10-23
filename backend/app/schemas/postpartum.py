from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class PostpartumRecordCreate(BaseModel):
    delivery_date: date
    delivery_type: str = Field("vaginal", description="vaginal, cesarean")
    recovery_notes: Optional[str] = ""
    lochia_status: Optional[str] = "normal"
    emotional_wellbeing_notes: Optional[str] = ""
    breastfeeding_status: Optional[str] = "exclusive"
    pelvic_floor_exercises_done: bool = False


class PostpartumRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    delivery_date: date
    delivery_type: str
    recovery_notes: str
    lochia_status: str
    emotional_wellbeing_notes: str
    breastfeeding_status: str
    pelvic_floor_exercises_done: bool
    created_at: datetime
    updated_at: datetime
