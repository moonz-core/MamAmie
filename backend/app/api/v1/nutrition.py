from datetime import date, datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, ForbiddenException
from app.db.session import get_db
from app.models.user import User
from app.models.nutrition import FoodLog, HydrationLog
from app.schemas.nutrition import (
    FoodLogCreate,
    FoodLogUpdate,
    FoodLogResponse,
    HydrationLogCreate,
    HydrationLogResponse,
    FoodImageAnalysisResponse,
    NutritionDailySummaryResponse
)
from app.integrations.nutrition.food_analyzer import FoodAnalyzerService

router = APIRouter(prefix="/nutrition", tags=["Nutrition & Food Photo Logging"])


@router.post("/analyze", response_model=FoodImageAnalysisResponse)
async def analyze_food(
    food_description: str = Query(..., description="Food name or photo description"),
    filename: Optional[str] = Query(None, description="Optional uploaded image filename"),
    current_user: User = Depends(get_current_user)
):
    """AI-assisted food identification and nutritional composition estimate."""
    return FoodAnalyzerService.analyze_food_input(food_text=food_description, filename=filename)


@router.post("/logs", response_model=FoodLogResponse, status_code=status.HTTP_201_CREATED)
async def log_food(
    data: FoodLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    log = FoodLog(
        user_id=current_user.id,
        meal_category=data.meal_category,
        image_url=data.image_url,
        ai_suggested_name=data.ai_suggested_name,
        user_confirmed_name=data.user_confirmed_name,
        portion_description=data.portion_description,
        ingredients=data.ingredients or "",
        calories_estimate=data.calories_estimate,
        protein_grams=data.protein_grams,
        carbs_grams=data.carbs_grams,
        fat_grams=data.fat_grams,
        iron_mg=data.iron_mg,
        folate_mcg=data.folate_mcg,
        calcium_mg=data.calcium_mg,
        is_ai_identified=data.is_ai_identified
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


@router.get("/logs", response_model=List[FoodLogResponse])
async def list_food_logs(
    target_date: Optional[date] = Query(None, description="Filter by date (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(FoodLog).where(FoodLog.user_id == current_user.id)
    if target_date:
        start_dt = datetime.combine(target_date, datetime.min.time(), tzinfo=timezone.utc)
        end_dt = datetime.combine(target_date, datetime.max.time(), tzinfo=timezone.utc)
        query = query.where(FoodLog.logged_at >= start_dt, FoodLog.logged_at <= end_dt)

    query = query.order_by(FoodLog.logged_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.delete("/logs/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_food_log(
    log_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(FoodLog).where(FoodLog.id == log_id))
    log = result.scalar_one_or_none()
    if not log:
        raise NotFoundException("Food entry not found")

    if log.user_id != current_user.id:
        raise ForbiddenException("Access denied to requested food log")

    await db.delete(log)
    await db.commit()


@router.post("/hydration", response_model=HydrationLogResponse, status_code=status.HTTP_201_CREATED)
async def log_hydration(
    data: HydrationLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    log = HydrationLog(
        user_id=current_user.id,
        amount_ml=data.amount_ml
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


@router.get("/daily-summary", response_model=NutritionDailySummaryResponse)
async def get_daily_summary(
    target_date: Optional[date] = Query(None, description="Target date (defaults to current date)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    day = target_date or datetime.now(timezone.utc).date()
    start_dt = datetime.combine(day, datetime.min.time(), tzinfo=timezone.utc)
    end_dt = datetime.combine(day, datetime.max.time(), tzinfo=timezone.utc)

    # Food logs
    food_res = await db.execute(
        select(FoodLog).where(
            FoodLog.user_id == current_user.id,
            FoodLog.logged_at >= start_dt,
            FoodLog.logged_at <= end_dt
        )
    )
    foods = food_res.scalars().all()

    # Hydration
    water_res = await db.execute(
        select(func.sum(HydrationLog.amount_ml)).where(
            HydrationLog.user_id == current_user.id,
            HydrationLog.logged_at >= start_dt,
            HydrationLog.logged_at <= end_dt
        )
    )
    total_water = water_res.scalar() or 0


    total_cal = sum(f.calories_estimate or 0 for f in foods)
    total_prot = sum(f.protein_grams or 0 for f in foods)
    total_carbs = sum(f.carbs_grams or 0 for f in foods)
    total_fat = sum(f.fat_grams or 0 for f in foods)
    total_iron = sum(f.iron_mg or 0 for f in foods)
    total_folate = sum(f.folate_mcg or 0 for f in foods)
    total_calcium = sum(f.calcium_mg or 0 for f in foods)

    return NutritionDailySummaryResponse(
        date_key=day.isoformat(),
        total_calories_estimate=round(total_cal, 1),
        total_protein_grams=round(total_prot, 1),
        total_carbs_grams=round(total_carbs, 1),
        total_fat_grams=round(total_fat, 1),
        total_iron_mg=round(total_iron, 1),
        total_folate_mcg=round(total_folate, 1),
        total_calcium_mg=round(total_calcium, 1),
        total_water_ml=int(total_water),
        meals_logged_count=len(foods)
    )
