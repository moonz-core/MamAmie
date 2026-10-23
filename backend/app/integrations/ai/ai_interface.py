from typing import Protocol, Optional
from app.schemas.ai import AIQueryResponse


class AIServiceProtocol(Protocol):
    async def answer_maternal_query(
        self,
        query: str,
        stage: Optional[str] = None,
        week: Optional[int] = None
    ) -> AIQueryResponse:
        """Answers maternal query with safety guardrails and citations."""
        ...
