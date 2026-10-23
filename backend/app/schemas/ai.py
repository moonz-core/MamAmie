from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class AIQueryRequest(BaseModel):
    query: str = Field(..., min_length=2, max_length=1000)
    stage: Optional[str] = None
    week: Optional[int] = None


class AISourceCitation(BaseModel):
    title: str
    source: str
    summary: str


class AIQueryResponse(BaseModel):
    answer: str
    is_educational_only: bool = True
    safety_escalation: bool = False
    emergency_notice: Optional[str] = None
    citations: List[AISourceCitation] = []
    disclaimer: str = (
        "MamAmie AI provides educational context based on reviewed clinical maternal guidelines. "
        "It does not diagnose medical conditions, prescribe medication, or replace your obstetrician. "
        "If you experience severe pain, bleeding, or reduced fetal movement, seek immediate medical care."
    )
