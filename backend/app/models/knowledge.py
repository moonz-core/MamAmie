from datetime import date, datetime, timezone
from typing import Optional

from sqlalchemy import Date, DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin


class KnowledgeSource(Base, UUIDMixin):
    __tablename__ = "knowledge_sources"

    title: Mapped[str] = mapped_column(String(512), nullable=False)
    issuing_organization: Mapped[str] = mapped_column(String(255), nullable=False)
    original_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    publication_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    last_reviewed_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    ingested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    version: Mapped[str] = mapped_column(String(128), default="unknown", nullable=False)
    content_hash: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    topic: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    maternal_stages: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    jurisdiction: Mapped[str] = mapped_column(String(128), default="global", index=True, nullable=False)
    source_type: Mapped[str] = mapped_column(String(64), default="official_document", nullable=False)
    review_status: Mapped[str] = mapped_column(String(64), default="unreviewed", index=True, nullable=False)
    license_note: Mapped[str] = mapped_column(Text, default="Verify reuse terms before redistribution.", nullable=False)
    original_filename: Mapped[str] = mapped_column(String(512), nullable=False)

    chunks: Mapped[list["KnowledgeChunk"]] = relationship(
        back_populates="source", cascade="all, delete-orphan", order_by="KnowledgeChunk.chunk_index"
    )


class KnowledgeChunk(Base, UUIDMixin):
    __tablename__ = "knowledge_chunks"
    __table_args__ = (UniqueConstraint("source_id", "chunk_index", name="uq_knowledge_source_chunk"),)

    source_id: Mapped[str] = mapped_column(ForeignKey("knowledge_sources.id", ondelete="CASCADE"), index=True, nullable=False)
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    section: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    page_number: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    token_count: Mapped[int] = mapped_column(Integer, nullable=False)
    embedding: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    embedding_model: Mapped[str] = mapped_column(String(128), default="local-hash-v1", nullable=False)

    source: Mapped[KnowledgeSource] = relationship(back_populates="chunks")
