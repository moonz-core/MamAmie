# MamAmie AI Backend

Production-minded, modular, and privacy-conscious backend service for **MamAmie AI** — an AI-powered maternal health and wellness companion supporting women before pregnancy, throughout pregnancy, and during postpartum recovery.

---

## Live Production Deployment
* **API Base URL:** `https://mamamie.onrender.com/api/v1`
* **Interactive Swagger Documentation:** [https://mamamie.onrender.com/docs](https://mamamie.onrender.com/docs)
* **ReDoc Documentation:** [https://mamamie.onrender.com/redoc](https://mamamie.onrender.com/redoc)
* **System Health Check:** [https://mamamie.onrender.com/health](https://mamamie.onrender.com/health)

---

## 1. Architecture & Technology Stack

* **Language:** Python 3.12 / 3.13
* **Web Framework:** [FastAPI](https://fastapi.tiangolo.com/) with asynchronous request handling
* **Database & ORM:** [SQLAlchemy 2.0](https://www.sqlalchemy.org/) (AsyncIO) with [Alembic](https://alembic.sqlalchemy.org/) migrations
* **Data Validation & Settings:** [Pydantic v2](https://docs.pydantic.dev/) and `pydantic-settings`
* **Authentication:** Stateless JWT Access Tokens + Rotating Refresh Tokens with instant database revocation
* **Password Hashing:** Passlib with Bcrypt
* **Storage Abstraction:** Pluggable file storage (local secure disk storage and S3-compatible cloud object storage)
* **AI & Clinical Guardrails:** Grounded Maternal Knowledge Engine with automatic obstetric red-flag detection and emergency escalation
* **Zero-Config Local Dev:** Configured out-of-the-box with SQLite (`aiosqlite`), with immediate single-variable toggle to PostgreSQL (`postgresql+asyncpg`) for production.

---

## 2. Directory Structure

```text
backend/
├── app/
│   ├── api/
│   │   ├── deps.py                  # Token validation & permission dependencies
│   │   └── v1/
│   │       ├── router.py            # Aggregate v1 endpoint registry
│   │       ├── auth.py              # Register, login, refresh, logout, /me
│   │       ├── onboarding.py        # Stage setup, progressive onboarding, consent
│   │       ├── pregnancy.py         # Deterministic dating, milestones, calculations
│   │       ├── planner.py           # Calendar journal entries & task management
│   │       ├── appointments.py      # Clinic visits, questions, status
│   │       ├── medications.py       # Prescriptions, supplements, adherence logs
│   │       ├── nutrition.py         # Food logs, photo analysis, hydration summary
│   │       ├── medical_records.py   # Secure PDF/image upload, access control
│   │       ├── education.py         # Medically reviewed articles by week & topic
│   │       ├── postpartum.py        # 4th trimester transition, recovery & lactation
│   │       ├── newborn.py           # Newborn profiles & UIP vaccination tracking
│   │       ├── ai_assistant.py      # Grounded assistant with emergency escalation
│   │       ├── notifications.py     # Notification preferences & reminder records
│   │       └── privacy.py           # GDPR / DPDP data export & account deletion
│   ├── core/
│   │   ├── config.py                # Centralized Pydantic settings & validation
│   │   ├── security.py              # JWT token generation & password hashing
│   │   ├── logging.py               # Sanitized structured logging (no PII/tokens)
│   │   └── exceptions.py            # Standardized application exception hierarchy
│   ├── db/
│   │   ├── base.py                  # DeclarativeBase, UUIDMixin, TimestampMixin
│   │   └── session.py               # Async engine, sessionmaker & init_db
│   ├── models/                      # SQLAlchemy 2.0 persistent ORM models
│   ├── schemas/                     # Validated Pydantic v2 request/response schemas
│   ├── integrations/
│   │   ├── ai/                      # Grounded clinical knowledge & LLM abstraction
│   │   ├── storage/                 # Local & S3 object storage adapters
│   │   └── nutrition/               # Food composition database & analysis
│   └── services/                    # Business logic (dating, vaccines, privacy)
├── migrations/                      # Alembic database migration scripts
├── tests/                           # Pytest automated test suite
├── .env.example                     # Documented configuration template
├── .env                             # Local development environment configuration
├── Dockerfile                       # Production container specification
├── docker-compose.yml               # Multi-container stack (Backend + PostgreSQL)
├── pyproject.toml                   # Project metadata & dependency definitions
├── requirements.txt                 # Pinned dependencies
└── README.md                        # Documentation
```

---

## 3. Quickstart & Local Setup

### Step 1: Create and Activate a Python Virtual Environment
```bash
cd backend
python -m venv .venv

# On Windows (PowerShell):
.venv\Scripts\Activate.ps1

# On macOS/Linux:
source .venv/bin/activate
```

### Step 2: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 3: Configure Environment
A local `.env` is not committed. The application uses documented defaults for SQLite and local extraction. Copy `.env.example` only if you need overrides:
```bash
Copy-Item .env.example .env
```

### Step 4: Run the Backend
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
The server will start at `http://localhost:8000`.

---

## 4. Interactive API Documentation

Once the backend is running, open your browser to explore the full interactive API documentation with request schemas, responses, and authorization try-it-out:

* **Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
* **ReDoc:** [http://localhost:8000/redoc](http://localhost:8000/redoc)
* **OpenAPI Specification:** [http://localhost:8000/openapi.json](http://localhost:8000/openapi.json)
* **Health Check:** [http://localhost:8000/health](http://localhost:8000/health)

---

## 5. Running Automated Tests

Run the full automated test suite with pytest:
```bash
pytest -v
```

The test suite covers:
1. User registration, duplicate email rejection, login, token refresh rotation, and logout.
2. Deterministic pregnancy dating (weeks, days, trimester, fruit comparisons) across Trimesters 1, 2, and 3.
3. Planner journal CRUD and **object-level cross-user authorization** (verifying that User B is blocked with 403 Forbidden from accessing User A's health records).
4. **Obstetric Red-Flag Emergency Escalation** (detecting symptoms such as vaginal bleeding, sudden severe headache with visual aura, or reduced fetal movement, immediately returning urgent clinical instructions).
5. Food logging, portion adjustments, and daily nutritional summary calculations.
6. Privacy compliance: portable JSON data export and permanent account/file erasure.

---

## 6. Docker Deployment

To launch the backend alongside a dedicated PostgreSQL 16 database using Docker Compose:

```bash
docker-compose up --build -d
```

---

## 7. Medical Safety & Clinical Guardrails

MamAmie AI adheres strictly to medical safety principles:
1. **No Autonomous Prescribing:** The backend never prescribes medication, calculates drug doses, or modifies treatment plans.
2. **Deterministic Calculations:** Gestational age and trimester calculations use audited, deterministic medical formulas (Naegele's rule) rather than probabilistic LLMs.
3. **Emergency Escalation:** Red-flag symptoms (e.g., vaginal bleeding, fluid leakage, severe headache with visual disturbances, decreased fetal movement) immediately trigger prominent clinical escalation notices directing users to emergency obstetric care.
4. **Data Isolation:** All personal health records, journal entries, and uploaded medical scans enforce strict tenant-level isolation.

## 8. Maternal-health RAG assistant (demonstration)

The assistant API is authenticated and available at `POST /api/v1/ai/query`,
`POST /api/v1/ai/triage`, `POST /api/v1/ai/reports/explain`, and
`GET /api/v1/knowledge/sources`. Run the Alembic migrations before deployment:

```powershell
alembic upgrade head
pytest -q
```

Development and test environments seed a small curated corpus of official WHO
and Indian government source summaries. Every seeded record is marked
`unreviewed_demo`; these summaries are not clinician reviewed, and licensing
must be checked before redistributing source material. Production does not seed
demo content. Add approved PDF, TXT, or Markdown documents locally using the
authenticated operator's development workflow:

```powershell
python -m app.services.knowledge_ingestion .\approved-guide.pdf --metadata .\guide-metadata.json
```

See `knowledge_sources/README.md` for the required metadata and source
governance. PDF page text is extracted where available; extraction gaps are
reported. Content changes at the same source URL replace the prior indexed
version. Hash-based local lexical vectors plus BM25 keyword matching and
reciprocal-rank fusion are the offline default. These vectors are not a
pretrained semantic embedding model. Optional OpenAI embeddings or OpenAI/Gemini
generation require an explicitly configured provider, backend-only credentials,
and per-request external-processing consent. No API credits are included or
assumed. In absence of a configured provider, the system returns retrieved
evidence excerpts or abstains; it does not fabricate live AI analysis.

Emergency phrase screening runs before retrieval and model generation. The
rules are a hackathon demonstration, are not clinically reviewed, can miss or
misclassify symptoms, and must not be represented as validated triage. Reports
currently accept pasted text only, are not persisted, and are not sent to an
external model without consent. PDF/image upload and OCR are not implemented in
this assistant flow. The existing separate medical-record feature is unchanged.

The iOS app requires an HTTPS backend URL configured in the assistant settings
and a user account; it stores the access token in Keychain. On-device symptom
screening is an early warning aid only. The iOS project cannot be compiled in
the Windows backend development environment; build it with Xcode on macOS.
