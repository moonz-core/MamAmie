from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from app.core.config import settings
from app.db.base import Base

db_url = settings.DATABASE_URL
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql+asyncpg://", 1)
elif db_url.startswith("postgresql://") and not db_url.startswith("postgresql+asyncpg://"):
    db_url = db_url.replace("postgresql://", "postgresql+asyncpg://", 1)

connect_args = {}
if "sqlite" in db_url:
    connect_args["check_same_thread"] = False
elif "postgresql+asyncpg" in db_url:
    connect_args["statement_cache_size"] = 0
    parsed = urlparse(db_url)
    if parsed.query:
        query_params = parse_qs(parsed.query)
        if "sslmode" in query_params:
            ssl_val = query_params.pop("sslmode")[0]
            if ssl_val in ("require", "verify-ca", "verify-full"):
                connect_args["ssl"] = "require"
        if "channel_binding" in query_params:
            query_params.pop("channel_binding")
        new_query = urlencode(query_params, doseq=True)
        db_url = urlunparse(parsed._replace(query=new_query))

engine = create_async_engine(
    db_url,
    echo=settings.DB_ECHO,
    future=True,
    connect_args=connect_args,
)

async_session_factory = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
