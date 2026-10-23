import json
from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_ENV: str = "development"
    DEBUG: bool = True
    PROJECT_NAME: str = "MamAmie AI Backend"
    API_V1_PREFIX: str = "/api/v1"
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    BACKEND_CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, list):
            return v
        return ["*"]

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./mamamie.db"
    DB_ECHO: bool = False

    # Security
    SECRET_KEY: str = "mamamie_super_secret_jwt_signing_key_at_least_32_characters"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    ALGORITHM: str = "HS256"

    # Storage
    STORAGE_PROVIDER: str = "local"
    LOCAL_STORAGE_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_BYTES: int = 10 * 1024 * 1024  # 10 MB
    ALLOWED_EXTENSIONS: Union[List[str], str] = [".pdf", ".jpg", ".jpeg", ".png", ".heic"]

    @field_validator("ALLOWED_EXTENSIONS", mode="before")
    def assemble_allowed_extensions(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except Exception:
                    pass
            return [i.strip() for i in v.split(",") if i.strip()]
        return v

    # S3
    S3_BUCKET_NAME: str = "mamamie-medical-records"
    S3_REGION: str = "ap-south-1"
    S3_ACCESS_KEY_ID: str = ""
    S3_SECRET_ACCESS_KEY: str = ""
    S3_ENDPOINT_URL: str = ""

    # AI
    AI_PROVIDER: str = "grounded_local"
    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    AI_MODEL_NAME: str = "gpt-4o-mini"
    AI_EMBEDDING_MODEL: str = "text-embedding-3-small"
    AI_REQUEST_TIMEOUT_SECONDS: int = 20
    AI_MAX_CONTEXT_CHARS: int = 9000

    # Notifications
    NOTIFICATION_PROVIDER: str = "mock"
    FCM_CREDENTIALS_PATH: str = ""

    # Rate Limiting
    AUTH_RATE_LIMIT_PER_MINUTE: int = 60
    AI_RATE_LIMIT_PER_MINUTE: int = 60

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
