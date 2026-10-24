from typing import Optional
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class AIInteraction(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "ai_interactions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    # Store no raw health questions or reports. Hashes support deduplication/audit only.
    user_query: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    assistant_response: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    query_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)
    safety_escalation_flagged: Mapped[bool] = mapped_column(Boolean, default=False, index=True, nullable=False)
    cited_source_ids: Mapped[Optional[list]] = mapped_column(JSON, default=list, nullable=True)
    latency_ms: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
