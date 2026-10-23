from typing import Protocol, BinaryIO


class StorageServiceProtocol(Protocol):
    async def save_file(self, file_content: bytes, filename: str, content_type: str) -> str:
        """Saves file and returns storage identifier or relative path."""
        ...

    async def get_file_content(self, file_path: str) -> bytes:
        """Retrieves raw file content."""
        ...

    async def delete_file(self, file_path: str) -> bool:
        """Deletes file from storage."""
        ...

    def generate_download_url(self, file_path: str, expires_in_seconds: int = 3600) -> str:
        """Generates a secure, temporary authorized download URL."""
        ...
