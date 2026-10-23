from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.core.config import settings
from app.core.logging import setup_logging, logger
from app.core.exceptions import MamAmieException
from app.db.session import init_db
from app.api.v1.router import api_v1_router
# Register all mapped classes before create_all, including knowledge index models.
from app import models as _models  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: configure logging and verify/create database schema
    setup_logging()
    logger.info("Initializing MamAmie AI Backend services...")
    await init_db()
    logger.info("Database initialized successfully.")
    yield
    # Shutdown
    logger.info("MamAmie AI Backend shutting down.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description=(
        "Production backend for MamAmie AI: Maternal health and wellness companion. "
        "Supports pregnancy planning, deterministic dating, planner journal, appointments, "
        "medications, nutrition tracking, medical records, postpartum recovery, newborn vaccination, "
        "and grounded AI assistance."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global Exception Handlers
@app.exception_handler(MamAmieException)
async def mamamie_exception_handler(request: Request, exc: MamAmieException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.detail,
                "extra": exc.extra
            }
        }
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Validation errors can carry the rejected input (including report text).
    # Pydantic's ctx/input can contain rejected health text. Expose only the
    # schema location and generic validation message to the caller.
    safe_errors = [{"loc": error.get("loc", []), "msg": error.get("msg", "Invalid value"),
                    "type": error.get("type", "validation_error")}
                   for error in exc.errors()]
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid request parameters",
                "details": safe_errors
            }
        }
    )


@app.get("/health", tags=["Health Check"])
async def health_check():
    """System health check endpoint verifying application availability."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "environment": settings.APP_ENV,
        "version": "1.0.0"
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": "Welcome to MamAmie AI Maternal Health API",
        "documentation": "/docs",
        "api_v1": settings.API_V1_PREFIX
    }


# Include API v1 Router
app.include_router(api_v1_router, prefix=settings.API_V1_PREFIX)
