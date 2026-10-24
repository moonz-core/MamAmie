"""Local/admin ingestion command: python -m app.services.knowledge_ingestion ..."""
from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from sqlalchemy import select

from app.db.session import async_session_factory, init_db
from app.models import KnowledgeChunk  # noqa: F401 - register model metadata
from app.services.knowledge_base import ingest_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest an approved maternal-health source into MamAmie's knowledge index.")
    parser.add_argument("document", type=Path, help="PDF, TXT, or Markdown document")
    parser.add_argument("--metadata", type=Path, required=True, help="JSON file with title, issuing_organization, and original_url")
    parser.add_argument("--allow-external-embeddings", action="store_true",
                        help="Send public document chunks to the configured embedding provider. Requires explicit setup.")
    return parser.parse_args()


async def run(document: Path, metadata_path: Path, *, allow_external_embeddings: bool) -> None:
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    for required in ("title", "issuing_organization", "original_url"):
        if not isinstance(metadata.get(required), str) or not metadata[required].strip():
            raise ValueError(f"Metadata requires a non-empty '{required}' field.")
    if not metadata["original_url"].startswith("https://"):
        raise ValueError("Source URLs must use HTTPS.")
    await init_db()
    async with async_session_factory() as session:
        source, inserted = await ingest_path(
            session, document, metadata, allow_external_embeddings=allow_external_embeddings,
        )
        await session.commit()
        chunk_count = len((await session.scalars(
            select(KnowledgeChunk).where(KnowledgeChunk.source_id == source.id)
        )).all())
        print(json.dumps({
            "source_id": source.id,
            "title": source.title,
            "chunk_count": chunk_count,
            "duplicate": not inserted,
            "review_status": source.review_status,
        }, ensure_ascii=False))


def main() -> None:
    args = parse_args()
    asyncio.run(run(args.document, args.metadata,
                    allow_external_embeddings=args.allow_external_embeddings))


if __name__ == "__main__":
    main()
