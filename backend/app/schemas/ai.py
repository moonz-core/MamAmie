from datetime import date
from typing import Literal, Optional

from pydantic import BaseModel, Field


MaternalStage = Literal["planning", "pregnant", "postpartum", "newborn"]


class AIQueryRequest(BaseModel):
    query: str = Field(..., min_length=2, max_length=2000)
    stage: Optional[MaternalStage] = None
    week: Optional[int] = Field(None, ge=1, le=42)
    language: str = Field("en", min_length=2, max_length=10)
    consent_to_external_processing: bool = False


class TriageRequest(BaseModel):
    symptoms: str = Field(..., min_length=2, max_length=4000)
    stage: Optional[MaternalStage] = None
    language: str = Field("en", min_length=2, max_length=10)


class ReportExplainRequest(BaseModel):
    report_text: str = Field(..., min_length=10, max_length=12000)
    question: str = Field(..., min_length=2, max_length=1000)
    stage: Optional[MaternalStage] = None
    consent_to_external_processing: bool = False


class AISourceCitation(BaseModel):
    citation_id: str
    source_id: Optional[str] = None
    title: str
    issuing_organization: str
    source: str
    original_url: Optional[str] = None
    section: Optional[str] = None
    page_number: Optional[int] = None
    publication_date: Optional[date] = None
    last_reviewed_date: Optional[date] = None
    review_status: str = "unreviewed"
    summary: str


class AIQueryResponse(BaseModel):
    answer: str
    citations: list[AISourceCitation] = Field(default_factory=list)
    is_educational_only: bool = True
    safety_escalation: bool = False
    emergency_notice: Optional[str] = None
    safety_level: Literal["educational", "professional_review", "emergency"] = "educational"
    safety_message: Optional[str] = None
    requires_professional_review: bool = False
    retrieval_status: str = "not_run"
    evidence_sufficient: bool = False
    generation_mode: str = "extractive"
    limitations: list[str] = Field(default_factory=list)
    disclaimer: str = (
        "MamAmie provides educational information and cautious symptom prompts. It does not diagnose, "
        "rule out a condition, prescribe treatment, or replace care from a qualified clinician. "
        "The demonstration triage rules and bundled source summaries have not been clinically reviewed."
    )


class KnowledgeSourceResponse(BaseModel):
    source_id: str
    title: str
    issuing_organization: str
    original_url: str
    publication_date: Optional[date] = None
    last_reviewed_date: Optional[date] = None
    ingested_at: str
    version: str
    topic: str
    maternal_stages: list[str]
    jurisdiction: str
    source_type: str
    review_status: str
    license_note: str
    chunk_count: int


class KnowledgeIngestResponse(BaseModel):
    source_id: str
    title: str
    chunk_count: int
    duplicate: bool
    review_status: str
