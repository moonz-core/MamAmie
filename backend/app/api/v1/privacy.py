from datetime import datetime, timezone
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import MamAmieException
from app.db.session import get_db
from app.models.user import User, UserProfile, ConsentRecord
from app.models.pregnancy import PregnancyJourney
from app.models.planner import PlannerEntry
from app.models.appointment import Appointment
from app.models.medication import Medication
from app.models.nutrition import FoodLog, HydrationLog
from app.models.medical_record import MedicalRecord
from app.models.newborn import NewbornProfile
from app.schemas.privacy import DeleteAccountRequest, DataExportResponse
from app.integrations.storage.local_storage import get_storage_service

router = APIRouter(prefix="/privacy", tags=["Privacy, Consent & Data Governance"])


@router.get("/export", response_model=DataExportResponse)
async def export_user_data(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Exports all personal and health information in a structured, portable JSON bundle."""
    # Profile
    p_res = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = p_res.scalar_one_or_none()

    # Journeys
    j_res = await db.execute(select(PregnancyJourney).where(PregnancyJourney.user_id == current_user.id))
    journeys = j_res.scalars().all()

    # Planner
    pl_res = await db.execute(select(PlannerEntry).where(PlannerEntry.user_id == current_user.id))
    entries = pl_res.scalars().all()

    # Appointments
    ap_res = await db.execute(select(Appointment).where(Appointment.user_id == current_user.id))
    appointments = ap_res.scalars().all()

    # Medications
    med_res = await db.execute(select(Medication).where(Medication.user_id == current_user.id))
    meds = med_res.scalars().all()

    # Food logs
    f_res = await db.execute(select(FoodLog).where(FoodLog.user_id == current_user.id))
    foods = f_res.scalars().all()

    # Medical records
    mr_res = await db.execute(select(MedicalRecord).where(MedicalRecord.user_id == current_user.id))
    records = mr_res.scalars().all()

    # Newborns
    nb_res = await db.execute(select(NewbornProfile).where(NewbornProfile.parent_user_id == current_user.id))
    newborns = nb_res.scalars().all()

    return DataExportResponse(
        export_timestamp=datetime.now(timezone.utc),
        user_profile={
            "email": current_user.email,
            "full_name": current_user.full_name,
            "stage": profile.current_stage if profile else "unknown",
            "timezone": profile.timezone if profile else "Asia/Kolkata"
        },
        pregnancy_history=[{"id": j.id, "lmp": str(j.lmp_date), "edd": str(j.edd_date), "status": j.status} for j in journeys],
        planner_entries=[{"id": e.id, "title": e.title, "day_key": e.day_key, "category": e.category} for e in entries],
        appointments=[{"id": a.id, "title": a.title, "date": str(a.scheduled_date), "clinic": a.clinician_or_clinic} for a in appointments],
        medications=[{"id": m.id, "name": m.name, "dose": f"{m.dose} {m.unit}"} for m in meds],
        nutrition_logs=[{"id": f.id, "meal": f.user_confirmed_name, "calories": f.calories_estimate} for f in foods],
        medical_records_metadata=[{"id": r.id, "title": r.title, "date": str(r.report_date)} for r in records],
        newborn_records=[{"id": n.id, "name": n.baby_name, "birth_date": str(n.birth_date)} for n in newborns]
    )


@router.post("/delete-account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account_and_data(
    data: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Permanently deletes user account, associated files, and all health records."""
    if data.confirmation.strip() != "DELETE MY ACCOUNT":
        raise MamAmieException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Confirmation string must match 'DELETE MY ACCOUNT' exactly"
        )

    # 1. Delete stored medical files from disk/storage
    storage = get_storage_service()
    records_res = await db.execute(select(MedicalRecord).where(MedicalRecord.user_id == current_user.id))
    for r in records_res.scalars().all():
        await storage.delete_file(r.file_path)

    # 2. Delete user entity (cascade will clean up related database entities)
    await db.delete(current_user)
    await db.commit()
