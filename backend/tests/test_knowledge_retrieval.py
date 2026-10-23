from app.services.knowledge_base import (
    LOCAL_EMBEDDING_MODEL,
    TextSegment,
    _bm25_scores,
    _chunk_segments,
    _split_markdown,
    local_vector,
)


def test_markdown_chunking_preserves_heading_and_page_metadata():
    segments = _split_markdown("# Antenatal visits\n\nFirst passage with useful maternal health context.\n\nSecond passage with another detail.")
    chunks = _chunk_segments(segments)
    assert chunks
    assert all(chunk.section == "Antenatal visits" for chunk in chunks)


def test_pdf_page_metadata_survives_chunking():
    chunks = _chunk_segments([TextSegment("A clinically relevant sentence with enough words to retain its useful context.", "Warning signs", 14)])
    assert chunks[0].section == "Warning signs"
    assert chunks[0].page_number == 14


def test_local_vector_is_deterministic_and_explicitly_lexical():
    assert len(local_vector("iron folate pregnancy")) == 384
    assert local_vector("iron folate pregnancy") == local_vector("iron folate pregnancy")
    assert LOCAL_EMBEDDING_MODEL == "local-hash-v1"


def test_keyword_ranking_rewards_exact_medical_terms():
    scores = _bm25_scores(["iron", "folate"], [["iron", "folate", "pregnancy"], ["breastfeeding", "newborn"]])
    assert scores[0][0] > scores[1][0]
    assert set(scores[0][1]) == {"iron", "folate"}
