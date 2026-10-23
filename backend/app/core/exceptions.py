from typing import Any, Dict, Optional
from fastapi import HTTPException, status


class MamAmieException(HTTPException):
    def __init__(
        self,
        status_code: int,
        detail: str,
        code: str = "ERROR",
        extra: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(status_code=status_code, detail=detail)
        self.code = code
        self.extra = extra or {}


class UnauthorizedException(MamAmieException):
    def __init__(self, detail: str = "Could not validate credentials"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            code="UNAUTHORIZED"
        )


class ForbiddenException(MamAmieException):
    def __init__(self, detail: str = "You do not have permission to access this resource"):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
            code="FORBIDDEN"
        )


class NotFoundException(MamAmieException):
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=detail,
            code="NOT_FOUND"
        )


class ConflictException(MamAmieException):
    def __init__(self, detail: str = "Resource conflict occurred"):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
            code="CONFLICT"
        )


class MedicalSafetyException(MamAmieException):
    def __init__(self, detail: str = "Operation violates maternal medical safety guardrails"):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=detail,
            code="MEDICAL_SAFETY_VIOLATION"
        )
