# Knowledge source governance

The included `demo_corpus.json` contains short, locally curated summaries with direct links to official sources. Every bundled record is tagged `unreviewed_demo`; none is represented as clinician-reviewed or as a complete clinical protocol. The summaries allow a working local retrieval demo without redistributing the source PDFs.

The demo corpus is intentionally small. Before a public or clinical launch, a qualified maternal-health clinician must review each passage and warning rule, and the product owner must confirm rights to use each source. IFCT, WHO, and government content can have different reuse terms; open access does not automatically grant product redistribution rights.

## Supported ingestion

The local command accepts selectable-text PDF, TXT, and Markdown. It stores source metadata, content hashes, section/page references, chunks, and local vector features in the configured application database. Re-ingesting unchanged content is a no-op; changed content at the same canonical URL replaces its previous index.

```powershell
cd backend
python -m app.services.knowledge_ingestion .\approved-guideline.pdf --metadata .\approved-guideline.metadata.json
```

Required metadata keys are `title`, `issuing_organization`, and an HTTPS `original_url`. Optional keys: `publication_date`, `last_reviewed_date`, `version`, `topic`, `maternal_stages`, `jurisdiction`, `source_type`, `review_status`, and `license_note`.

Scanned PDFs are not OCR'd. The importer reports pages with no selectable text and rejects documents with no extractable text. Review extracted content and page references before relying on it.

## Retrieval and generation modes

- Offline default: BM25 keyword retrieval plus a deterministic local hashed lexical vector. This is **not a pretrained semantic embedding model**; it supports a functional no-credential demonstration and exposes its retrieval mode to clients.
- Optional semantic vector indexing: set `AI_PROVIDER=openai`, configure the backend-only `OPENAI_API_KEY`, and explicitly pass `--allow-external-embeddings` when indexing public documents. This sends document text to the configured embedding provider.
- Answer generation can use configured OpenAI or Gemini, but only if the authenticated request includes `consent_to_external_processing: true`. Without consent, local retrieval and extractive answers are used. API keys never belong in the iOS app.
- Hosted providers are optional and use backend settings; an account does not guarantee available API credits. Provider failures fall back to extractive evidence or abstention. Gemini does not provide query embeddings here; retrieval remains hybrid keyword plus local hashed vectors.

The code does not claim that the offline hash vector provides semantic understanding. Retrieval scores are relevance signals only, never evidence of clinical correctness.
