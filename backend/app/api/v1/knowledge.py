from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.knowledge import KnowledgeSource
from app.models.user import User
from app.schemas.ai import KnowledgeSourceResponse
from app.services.knowledge_base import ensure_demo_sources

router = APIRouter(prefix="/knowledge", tags=["Maternal Knowledge Sources"])


@router.get("/sources", response_model=list[KnowledgeSourceResponse])
async def list_knowledge_sources(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await ensure_demo_sources(db)
    sources = (await db.execute(
        select(KnowledgeSource).options(selectinload(KnowledgeSource.chunks))
        .order_by(KnowledgeSource.issuing_organization, KnowledgeSource.title)
    )).scalars().all()
    return [KnowledgeSourceResponse(
        source_id=source.id, title=source.title, issuing_organization=source.issuing_organization,
        original_url=source.original_url, publication_date=source.publication_date,
        last_reviewed_date=source.last_reviewed_date, ingested_at=source.ingested_at.isoformat(),
        version=source.version, topic=source.topic, maternal_stages=source.maternal_stages,
        jurisdiction=source.jurisdiction, source_type=source.source_type,
        review_status=source.review_status, license_note=source.license_note,
        chunk_count=len(source.chunks),
    ) for source in sources]
