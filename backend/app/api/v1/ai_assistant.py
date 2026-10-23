import time
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.ai_interaction import AIInteraction
from app.schemas.ai import AIQueryRequest, AIQueryResponse
from app.integrations.ai.grounded_ai import GroundedAIService

router = APIRouter(prefix="/ai-assistant", tags=["Grounded Maternal AI Assistant"])

ai_engine = GroundedAIService()


@router.post("/query", response_model=AIQueryResponse)
async def query_maternal_ai(
    data: AIQueryRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    start_time = time.time()
    response = await ai_engine.answer_maternal_query(
        query=data.query,
        stage=data.stage,
        week=data.week
    )
    latency_ms = int((time.time() - start_time) * 1000)

    # Record AI interaction audit log
    interaction = AIInteraction(
        user_id=current_user.id,
        user_query=data.query,
        assistant_response=response.answer,
        safety_escalation_flagged=response.safety_escalation,
        cited_source_ids=[c.title for c in response.citations],
        latency_ms=latency_ms
    )
    db.add(interaction)
    await db.commit()

    return response
