import os
import uuid
import aiofiles
from pathlib import Path
from app.core.config import settings


class LocalStorageService:
    def __init__(self, base_dir: str = settings.LOCAL_STORAGE_DIR):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    async def save_file(self, file_content: bytes, filename: str, content_type: str) -> str:
        ext = Path(filename).suffix.lower()
        unique_name = f"{uuid.uuid4().hex}{ext}"
        destination = self.base_dir / unique_name

        async with aiofiles.open(destination, "wb") as f:
            await f.write(file_content)

        return unique_name

    async def get_file_content(self, file_path: str) -> bytes:
        target = self.base_dir / Path(file_path).name
        if not target.exists():
            raise FileNotFoundError(f"File {file_path} not found")

        async with aiofiles.open(target, "rb") as f:
            return await f.read()

    async def delete_file(self, file_path: str) -> bool:
        target = self.base_dir / Path(file_path).name
        if target.exists():
            target.unlink()
            return True
        return False

    def generate_download_url(self, file_path: str, expires_in_seconds: int = 3600) -> str:
        # In local development, route through our secure files endpoint
        filename = Path(file_path).name
        return f"{settings.API_V1_PREFIX}/medical-records/download/{filename}"


def get_storage_service() -> LocalStorageService:
    return LocalStorageService()
