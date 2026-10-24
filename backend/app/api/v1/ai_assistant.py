import hashlib
import hmac
import time

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.api.deps import get_current_user
from app.db.session import get_db
from app.integrations.ai.grounded_ai import GroundedAIService
from app.models.ai_interaction import AIInteraction
from app.models.user import User
from app.schemas.ai import AIQueryRequest, AIQueryResponse, ReportExplainRequest, TriageRequest
from app.services.knowledge_base import ensure_demo_sources

router = APIRouter(prefix="/ai-assistant", tags=["Grounded Maternal AI Assistant"])
ai_engine = GroundedAIService()


def _query_digest(query: str) -> str:
    return hmac.new(settings.SECRET_KEY.encode("utf-8"), query.strip().encode("utf-8"), hashlib.sha256).hexdigest()


@router.post("/query", response_model=AIQueryResponse)
async def query_maternal_ai(
    data: AIQueryRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    start_time = time.monotonic()
    # Safety runs before any index access. Seed only for ordinary educational requests.
    if not ai_engine.answer_is_emergency(data.query, data.stage):
        await ensure_demo_sources(db)
    response = await ai_engine.answer_maternal_query(
        query=data.query, stage=data.stage, week=data.week, language=data.language,
        allow_external_processing=data.consent_to_external_processing, db=db,
    )
    db.add(AIInteraction(
        user_id=current_user.id,
        user_query=None,
        assistant_response=None,
        query_hash=_query_digest(data.query),
        safety_escalation_flagged=response.safety_escalation,
        cited_source_ids=[citation.citation_id for citation in response.citations],
        latency_ms=int((time.monotonic() - start_time) * 1000),
    ))
    await db.commit()
    return response


@router.post("/triage", response_model=AIQueryResponse)
async def triage_maternal_symptoms(
    data: TriageRequest,
    current_user: User = Depends(get_current_user),
):
    # No database/vector lookup or LLM call occurs after auth; nothing is stored.
    return await ai_engine.triage_symptoms(data.symptoms, data.stage, data.language)


@router.post("/reports/explain", response_model=AIQueryResponse)
async def explain_report_text(
    data: ReportExplainRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Pasted text is request-scoped only; this route neither persists nor uploads it.
    await ensure_demo_sources(db)
    return await ai_engine.answer_maternal_query(
        query=data.question, stage=data.stage,
        allow_external_processing=data.consent_to_external_processing,
        db=db, report_text=data.report_text,
    )
