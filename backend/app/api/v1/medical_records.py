import io
from pathlib import Path
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from fastapi.responses import Response, StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.config import settings
from app.core.exceptions import NotFoundException, ForbiddenException, MamAmieException
from app.db.session import get_db
from app.models.user import User
from app.models.medical_record import MedicalRecord
from app.schemas.medical_record import (
    MedicalRecordResponse,
    SecureDownloadUrlResponse
)
from app.integrations.storage.local_storage import get_storage_service

router = APIRouter(prefix="/medical-records", tags=["Medical Reports & Test Results"])


@router.post("/upload", response_model=MedicalRecordResponse, status_code=status.HTTP_201_CREATED)
async def upload_medical_record(
    title: str = Form(...),
    report_type: str = Form("General Report"),
    report_date: date = Form(...),
    clinician_name: Optional[str] = Form(""),
    notes: Optional[str] = Form(""),
    follow_up_date: Optional[date] = Form(None),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Validate extension
    ext = Path(file.filename or "").suffix.lower()
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise MamAmieException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File extension '{ext}' is not permitted. Allowed: {settings.ALLOWED_EXTENSIONS}"
        )

    content = await file.read()
    if len(content) > settings.MAX_UPLOAD_SIZE_BYTES:
        raise MamAmieException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds maximum allowed size of {settings.MAX_UPLOAD_SIZE_BYTES // (1024 * 1024)}MB"
        )

    storage = get_storage_service()
    stored_path = await storage.save_file(
        file_content=content,
        filename=file.filename or f"record{ext}",
        content_type=file.content_type or "application/octet-stream"
    )

    record = MedicalRecord(
        user_id=current_user.id,
        title=title.strip(),
        file_path=stored_path,
        file_name=file.filename or f"report{ext}",
        file_size_bytes=len(content),
        mime_type=file.content_type or "application/pdf",
        report_type=report_type,
        report_date=report_date,
        clinician_name=clinician_name or "",
        notes=notes or "",
        follow_up_date=follow_up_date
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


@router.get("/", response_model=List[MedicalRecordResponse])
async def list_medical_records(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(MedicalRecord)
        .where(MedicalRecord.user_id == current_user.id)
        .order_by(MedicalRecord.report_date.desc())
    )
    return result.scalars().all()


@router.get("/{record_id}", response_model=MedicalRecordResponse)
async def get_medical_record(
    record_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(MedicalRecord).where(MedicalRecord.id == record_id))
    record = result.scalar_one_or_none()
    if not record:
        raise NotFoundException("Medical record not found")

    if record.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested medical report")

    return record


@router.get("/{record_id}/download-url", response_model=SecureDownloadUrlResponse)
async def get_download_url(
    record_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(MedicalRecord).where(MedicalRecord.id == record_id))
    record = result.scalar_one_or_none()
    if not record:
        raise NotFoundException("Medical record not found")

    if record.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested medical report")

    storage = get_storage_service()
    url = storage.generate_download_url(record.file_path)
    return SecureDownloadUrlResponse(download_url=url, expires_in_seconds=3600)


@router.get("/download/{filename}")
async def download_record_file(
    filename: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify user owns the record associated with this filename
    result = await db.execute(
        select(MedicalRecord).where(
            MedicalRecord.file_path == filename,
            MedicalRecord.user_id == current_user.id
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise NotFoundException("Report file not found or unauthorized")

    storage = get_storage_service()
    try:
        content = await storage.get_file_content(filename)
    except FileNotFoundError:
        raise NotFoundException("File missing from storage")

    return StreamingResponse(
        io.BytesIO(content),
        media_type=record.mime_type,
        headers={"Content-Disposition": f'attachment; filename="{record.file_name}"'}
    )


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medical_record(
    record_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(MedicalRecord).where(MedicalRecord.id == record_id))
    record = result.scalar_one_or_none()
    if not record:
        raise NotFoundException("Medical record not found")

    if record.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested medical report")

    # Delete physical file
    storage = get_storage_service()
    await storage.delete_file(record.file_path)

    await db.delete(record)
    await db.commit()
