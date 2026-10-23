from typing import Optional
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, UUIDMixin, TimestampMixin


class AIInteraction(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "ai_interactions"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    user_query: Mapped[str] = mapped_column(Text, nullable=False)
    assistant_response: Mapped[str] = mapped_column(Text, nullable=False)
    safety_escalation_flagged: Mapped[bool] = mapped_column(Boolean, default=False, index=True, nullable=False)
    cited_source_ids: Mapped[Optional[list]] = mapped_column(JSON, default=list, nullable=True)
    latency_ms: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
