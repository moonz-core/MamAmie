# Storage integrations package
from app.integrations.storage.storage_interface import StorageServiceProtocol
from app.integrations.storage.local_storage import LocalStorageService, get_storage_service

__all__ = ["StorageServiceProtocol", "LocalStorageService", "get_storage_service"]
