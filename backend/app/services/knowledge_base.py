"""Persistent source ingestion and transparent hybrid retrieval.

The default vectorizer is a local, hashed lexical vector. It is deliberately not
described as a language model embedding. OpenAI embeddings are an opt-in adapter;
query text is only sent to it when the request carries explicit consent.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import uuid
from dataclasses import dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Optional

import httpx
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.models.knowledge import KnowledgeChunk, KnowledgeSource


TOKEN_RE = re.compile(r"[\wÀ-ÖØ-öø-ÿ]+", re.UNICODE)
STOP_WORDS = {
    "a", "about", "am", "an", "and", "are", "as", "at", "be", "been", "but", "by", "can",
    "could", "did", "do", "does", "for", "from", "had", "has", "have", "how", "i", "if", "in",
    "is", "it", "me", "my", "of", "on", "or", "please", "should", "tell", "that", "the", "this",
    "to", "was", "what", "when", "where", "which", "with", "would", "you", "your",
}
LOCAL_EMBEDDING_MODEL = "local-hash-v1"
VECTOR_SIZE = 384
DEMO_CORPUS_PATH = Path(__file__).resolve().parents[2] / "knowledge_sources" / "demo_corpus.json"


@dataclass
class TextSegment:
    text: str
    section: Optional[str] = None
    page_number: Optional[int] = None


@dataclass
class RetrievedEvidence:
    chunk: KnowledgeChunk
    source: KnowledgeSource
    score: float
    keyword_score: float
    vector_score: Optional[float]
    matched_terms: list[str]

    def citation(self, citation_id: str) -> dict[str, Any]:
        return {
            "citation_id": citation_id,
            "source_id": self.source.id,
            "title": self.source.title,
            "issuing_organization": self.source.issuing_organization,
            "section": self.chunk.section,
            "page_number": self.chunk.page_number,
            "original_url": self.source.original_url,
            "publication_date": self.source.publication_date,
            "last_reviewed_date": self.source.last_reviewed_date,
            "review_status": self.source.review_status,
            "excerpt": self.chunk.text[:1200],
        }


def _tokens(text: str, *, remove_stop_words: bool = False) -> list[str]:
    values = [part.casefold() for part in TOKEN_RE.findall(text)]
    if remove_stop_words:
        return [part for part in values if part not in STOP_WORDS and len(part) > 1]
    return values


def local_vector(text: str) -> list[float]:
    """Fast deterministic lexical feature hashing for an offline development index."""
    vector = [0.0] * VECTOR_SIZE
    tokens = _tokens(text, remove_stop_words=True)
    for token in tokens:
        digest = hashlib.blake2b(token.encode("utf-8"), digest_size=8).digest()
        index = int.from_bytes(digest[:4], "big") % VECTOR_SIZE
        sign = 1.0 if digest[4] & 1 else -1.0
        vector[index] += sign
    norm = math.sqrt(sum(value * value for value in vector))
    if norm:
        vector = [value / norm for value in vector]
    return vector


async def embedding_for(text: str, *, allow_external: bool = False) -> tuple[list[float], str]:
    if allow_external and settings.AI_PROVIDER == "openai" and settings.OPENAI_API_KEY:
        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
            response = await client.post(
                "https://api.openai.com/v1/embeddings",
                headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
                json={"model": settings.AI_EMBEDDING_MODEL, "input": text[:8000]},
            )
            response.raise_for_status()
            data = response.json()["data"][0]["embedding"]
            return [float(value) for value in data], settings.AI_EMBEDDING_MODEL
    return local_vector(text), LOCAL_EMBEDDING_MODEL


def _cosine(left: Optional[list], right: Optional[list]) -> Optional[float]:
    if not left or not right or len(left) != len(right):
        return None
    left_norm = math.sqrt(sum(float(x) ** 2 for x in left))
    right_norm = math.sqrt(sum(float(x) ** 2 for x in right))
    if not left_norm or not right_norm:
        return None
    return sum(float(a) * float(b) for a, b in zip(left, right)) / (left_norm * right_norm)


def _split_markdown(text: str) -> list[TextSegment]:
    segments: list[TextSegment] = []
    heading = None
    body: list[str] = []
    for line in text.splitlines():
        match = re.match(r"^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$", line)
        if match:
            if "\n".join(body).strip():
                segments.append(TextSegment("\n".join(body).strip(), heading))
            heading = match.group(1).strip()
            body = []
        else:
            body.append(line)
    if "\n".join(body).strip():
        segments.append(TextSegment("\n".join(body).strip(), heading))
    return segments


def _chunk_segments(segments: list[TextSegment], max_chars: int = 1500, overlap_chars: int = 180) -> list[TextSegment]:
    chunks: list[TextSegment] = []
    for segment in segments:
        paragraphs = [p.strip() for p in re.split(r"\n\s*\n", segment.text) if p.strip()]
        if not paragraphs:
            paragraphs = [segment.text.strip()]
        current = ""
        for paragraph in paragraphs:
            parts = [paragraph]
            if len(paragraph) > max_chars:
                parts = re.split(r"(?<=[.!?])\s+", paragraph)
            for part in parts:
                if not part:
                    continue
                if current and len(current) + len(part) + 2 > max_chars:
                    chunks.append(TextSegment(current, segment.section, segment.page_number))
                    tail_match = re.search(r"[^.!?\n]{1," + str(overlap_chars) + r"}$", current)
                    current = (tail_match.group(0).strip() + " ") if tail_match else ""
                current = f"{current}\n\n{part}".strip()
        if current.strip():
            chunks.append(TextSegment(current.strip(), segment.section, segment.page_number))
    return [chunk for chunk in chunks if len(_tokens(chunk.text)) >= 4]


def extract_segments(path: Path) -> list[TextSegment]:
    extension = path.suffix.lower()
    if extension == ".pdf":
        try:
            from pypdf import PdfReader
        except ImportError as exc:
            raise ValueError("PDF ingestion requires pypdf. Install the backend requirements first.") from exc
        reader = PdfReader(str(path))
        segments = []
        for index, page in enumerate(reader.pages, start=1):
            text = (page.extract_text() or "").strip()
            if text:
                segments.append(TextSegment(text, page_number=index))
        if not segments:
            raise ValueError("No selectable text was extracted. Scanned PDFs need OCR and are not supported by this importer.")
        if len(segments) < len(reader.pages):
            print(f"Warning: text extraction returned content from {len(segments)} of {len(reader.pages)} pages.")
        return segments
    if extension == ".md":
        return _split_markdown(path.read_text(encoding="utf-8"))
    if extension == ".txt":
        return [TextSegment(path.read_text(encoding="utf-8"))]
    raise ValueError("Unsupported source type. Use PDF, TXT, or Markdown.")


async def ingest_text(
    session: AsyncSession,
    *,
    text: str,
    metadata: dict[str, Any],
    original_filename: str,
    allow_external_embeddings: bool = False,
    segments: Optional[list[TextSegment]] = None,
) -> tuple[KnowledgeSource, bool]:
    cleaned = text.strip()
    if len(cleaned) < 40:
        raise ValueError("The document contains too little readable text to index.")
    content_hash = hashlib.sha256(cleaned.encode("utf-8")).hexdigest()
    url = metadata["original_url"]
    existing = await session.scalar(select(KnowledgeSource).where(
        KnowledgeSource.content_hash == content_hash,
        KnowledgeSource.original_url == url,
    ))
    if existing:
        return existing, False

    prior = await session.scalar(select(KnowledgeSource).where(KnowledgeSource.original_url == url))
    if prior:
        await session.execute(delete(KnowledgeChunk).where(KnowledgeChunk.source_id == prior.id))
        await session.delete(prior)
        await session.flush()

    def as_date(value: Any) -> Optional[date]:
        if not value:
            return None
        return value if isinstance(value, date) else date.fromisoformat(str(value))

    source = KnowledgeSource(
        id=str(uuid.uuid4()), title=metadata["title"],
        issuing_organization=metadata["issuing_organization"], original_url=url,
        publication_date=as_date(metadata.get("publication_date")),
        last_reviewed_date=as_date(metadata.get("last_reviewed_date")),
        ingested_at=datetime.now(timezone.utc), version=metadata.get("version", "unknown"),
        content_hash=content_hash, topic=metadata.get("topic", "general maternal health"),
        maternal_stages=metadata.get("maternal_stages", []), jurisdiction=metadata.get("jurisdiction", "global"),
        source_type=metadata.get("source_type", "official_document"),
        review_status=metadata.get("review_status", "unreviewed"),
        license_note=metadata.get("license_note", "Verify reuse terms before redistribution."),
        original_filename=original_filename,
    )
    session.add(source)
    await session.flush()
    segment_list = segments or [TextSegment(cleaned)]
    chunked = _chunk_segments(segment_list)
    for index, chunk in enumerate(chunked):
        vector, model_name = await embedding_for(chunk.text, allow_external=allow_external_embeddings)
        session.add(KnowledgeChunk(
            id=str(uuid.uuid4()), source_id=source.id, chunk_index=index, text=chunk.text,
            section=chunk.section, page_number=chunk.page_number,
            token_count=len(_tokens(chunk.text)), embedding=vector, embedding_model=model_name,
        ))
    if not chunked:
        await session.delete(source)
        raise ValueError("No coherent text chunks could be created from the document.")
    await session.flush()
    return source, True


async def ingest_path(
    session: AsyncSession,
    path: Path,
    metadata: dict[str, Any],
    *,
    allow_external_embeddings: bool = False,
) -> tuple[KnowledgeSource, bool]:
    if not path.is_file():
        raise ValueError("Source file does not exist.")
    if path.stat().st_size > 30 * 1024 * 1024:
        raise ValueError("Source files are limited to 30 MB.")
    segments = extract_segments(path)
    text = "\n\n".join(segment.text for segment in segments)
    return await ingest_text(session, text=text, segments=segments, metadata=metadata,
                             original_filename=path.name, allow_external_embeddings=allow_external_embeddings)


async def ensure_demo_sources(session: AsyncSession) -> None:
    if settings.APP_ENV.lower() not in {"development", "test", "testing"}:
        return
    count = await session.scalar(select(KnowledgeSource.id).limit(1))
    if count:
        return
    manifest = json.loads(DEMO_CORPUS_PATH.read_text(encoding="utf-8"))
    for item in manifest["sources"]:
        sections = [TextSegment(part, info.get("heading"), info.get("page"))
                    for info in item.pop("sections", [])
                    for part in [item["content"]]]
        await ingest_text(session, text=item["content"], metadata=item,
                           original_filename=item["original_filename"], segments=sections)
    await session.commit()


def _bm25_scores(query_terms: list[str], documents: list[list[str]]) -> list[tuple[float, list[str]]]:
    n_docs = len(documents)
    if not n_docs:
        return []
    average_length = sum(len(doc) for doc in documents) / n_docs or 1
    document_frequency: dict[str, int] = {}
    for doc in documents:
        for term in set(doc):
            document_frequency[term] = document_frequency.get(term, 0) + 1
    results = []
    for doc in documents:
        frequencies: dict[str, int] = {}
        for term in doc:
            frequencies[term] = frequencies.get(term, 0) + 1
        score = 0.0
        matches = []
        for term in set(query_terms):
            frequency = frequencies.get(term, 0)
            if not frequency:
                continue
            matches.append(term)
            idf = math.log(1 + (n_docs - document_frequency.get(term, 0) + 0.5) /
                           (document_frequency.get(term, 0) + 0.5))
            denominator = frequency + 1.5 * (1 - 0.75 + 0.75 * len(doc) / average_length)
            score += idf * frequency * 2.5 / denominator
        results.append((score, matches))
    return results


async def retrieve(
    session: AsyncSession,
    query: str,
    *,
    stage: Optional[str] = None,
    allow_external_processing: bool = False,
    limit: int = 5,
) -> tuple[list[RetrievedEvidence], bool, str]:
    terms = _tokens(query, remove_stop_words=True)
    if not terms:
        return [], False, "no_search_terms"
    records = (await session.execute(
        select(KnowledgeChunk).options(selectinload(KnowledgeChunk.source))
    )).scalars().all()
    if not records:
        return [], False, "knowledge_base_empty"

    document_tokens = [_tokens(record.text, remove_stop_words=True) for record in records]
    bm25 = _bm25_scores(terms, document_tokens)
    keyword_order = sorted(range(len(records)), key=lambda i: bm25[i][0], reverse=True)
    try:
        query_embedding, model_name = await embedding_for(query, allow_external=allow_external_processing)
    except Exception:
        query_embedding, model_name = local_vector(query), LOCAL_EMBEDDING_MODEL
    vector_values = []
    for record in records:
        vector_values.append(_cosine(record.embedding, query_embedding)
                             if record.embedding_model == model_name else None)
    vector_order = sorted(
        (i for i, score in enumerate(vector_values) if score is not None),
        key=lambda i: vector_values[i] or -1, reverse=True,
    )
    ranks: dict[int, float] = {}
    for order in (keyword_order, vector_order):
        for rank, index in enumerate(order, start=1):
            ranks[index] = ranks.get(index, 0.0) + 1.0 / (60 + rank)

    candidates = []
    for index, rank_score in ranks.items():
        record = records[index]
        source = record.source
        # Stage is a small preference, never a hard filter.
        if stage and stage in (source.maternal_stages or []):
            rank_score *= 1.04
        candidates.append(RetrievedEvidence(
            chunk=record, source=source, score=rank_score,
            keyword_score=bm25[index][0], vector_score=vector_values[index],
            matched_terms=bm25[index][1],
        ))
    candidates.sort(key=lambda item: item.score, reverse=True)

    selected: list[RetrievedEvidence] = []
    per_source: dict[str, int] = {}
    for evidence in candidates:
        if evidence.keyword_score <= 0 and (evidence.vector_score is None or evidence.vector_score <= 0.15):
            continue
        source_id = evidence.source.id
        if per_source.get(source_id, 0) >= 2:
            continue
        selected.append(evidence)
        per_source[source_id] = per_source.get(source_id, 0) + 1
        if len(selected) >= limit:
            break

    matched = set(term for evidence in selected for term in evidence.matched_terms)
    coverage = len(matched) / max(1, len(set(terms)))
    sufficient = bool(selected) and (coverage >= 0.16 or selected[0].keyword_score >= 0.7)
    status = "hybrid_local_hash" if model_name == LOCAL_EMBEDDING_MODEL else "hybrid_openai_embedding"
    if not vector_order:
        status = "keyword_only_embedding_unavailable_or_not_consented"
    return selected, sufficient, status
