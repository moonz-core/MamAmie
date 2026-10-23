from fastapi import APIRouter, Depends, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User, UserProfile, ConsentRecord
from app.models.pregnancy import PregnancyJourney
from app.models.postpartum import PostpartumRecord
from app.schemas.profile import (
    UserProfileResponse,
    UserProfileUpdateRequest,
    OnboardingSetupRequest,
    ConsentRequest,
    ConsentResponse
)

router = APIRouter(prefix="/onboarding", tags=["Onboarding & Profile"])


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = UserProfile(user_id=current_user.id, current_stage="pregnant")
        db.add(profile)
        await db.commit()
        await db.refresh(profile)
    return profile


@router.put("/profile", response_model=UserProfileResponse)
async def update_profile(
    data: UserProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    update_dict = data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(profile, field, value)

    await db.commit()
    await db.refresh(profile)
    return profile


@router.post("/setup", response_model=UserProfileResponse)
async def setup_onboarding(
    data: OnboardingSetupRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    profile.current_stage = data.current_stage
    if data.diet_preferences:
        profile.diet_preferences = data.diet_preferences
    if data.food_allergies:
        profile.food_allergies = data.food_allergies
    profile.is_onboarding_completed = True

    # If stage is pregnant, record pregnancy journey
    if data.current_stage == "pregnant" and (data.lmp_date or data.edd_date):
        # Archive any prior active journeys
        await db.execute(
            update(PregnancyJourney)
            .where(PregnancyJourney.user_id == current_user.id, PregnancyJourney.is_active == True)
            .values(is_active=False)
        )
        journey = PregnancyJourney(
            user_id=current_user.id,
            lmp_date=data.lmp_date,
            edd_date=data.edd_date,
            is_active=True,
            status="active"
        )
        db.add(journey)

    # If stage is postpartum, record postpartum details
    elif data.current_stage == "postpartum" and data.delivery_date:
        postpartum = PostpartumRecord(
            user_id=current_user.id,
            delivery_date=data.delivery_date,
            recovery_notes="Onboarding record"
        )
        db.add(postpartum)

    # Save explicit consent
    if data.consent_health_data:
        consent = ConsentRecord(
            user_id=current_user.id,
            consent_type="health_data_processing",
            granted=True,
            notes="Granted during onboarding flow"
        )
        db.add(consent)

    await db.commit()
    await db.refresh(profile)
    return profile


@router.post("/consent", response_model=ConsentResponse)
async def record_consent(
    data: ConsentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    consent = ConsentRecord(
        user_id=current_user.id,
        consent_type=data.consent_type,
        granted=data.granted,
        notes=data.notes
    )
    db.add(consent)
    await db.commit()
    await db.refresh(consent)
    return consent
