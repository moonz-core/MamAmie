from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.onboarding import router as onboarding_router
from app.api.v1.pregnancy import router as pregnancy_router
from app.api.v1.planner import router as planner_router
from app.api.v1.appointments import router as appointments_router
from app.api.v1.medications import router as medications_router
from app.api.v1.nutrition import router as nutrition_router
from app.api.v1.medical_records import router as medical_records_router
from app.api.v1.education import router as education_router
from app.api.v1.postpartum import router as postpartum_router
from app.api.v1.newborn import router as newborn_router
from app.api.v1.ai_assistant import router as ai_assistant_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.privacy import router as privacy_router

api_v1_router = APIRouter()

api_v1_router.include_router(auth_router)
api_v1_router.include_router(onboarding_router)
api_v1_router.include_router(pregnancy_router)
api_v1_router.include_router(planner_router)
api_v1_router.include_router(appointments_router)
api_v1_router.include_router(medications_router)
api_v1_router.include_router(nutrition_router)
api_v1_router.include_router(medical_records_router)
api_v1_router.include_router(education_router)
api_v1_router.include_router(postpartum_router)
api_v1_router.include_router(newborn_router)
api_v1_router.include_router(ai_assistant_router)
api_v1_router.include_router(notifications_router)
api_v1_router.include_router(privacy_router)
