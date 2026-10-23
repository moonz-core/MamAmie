from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class FoodLogCreate(BaseModel):
    meal_category: str = Field("lunch", description="breakfast, lunch, dinner, snack, other")
    image_url: Optional[str] = None
    ai_suggested_name: Optional[str] = None
    user_confirmed_name: str = Field(..., min_length=1, max_length=255)
    portion_description: str = Field("1 medium serving", max_length=128)
    ingredients: Optional[str] = ""
    calories_estimate: Optional[float] = None
    protein_grams: Optional[float] = None
    carbs_grams: Optional[float] = None
    fat_grams: Optional[float] = None
    iron_mg: Optional[float] = None
    folate_mcg: Optional[float] = None
    calcium_mg: Optional[float] = None
    is_ai_identified: bool = False


class FoodLogUpdate(BaseModel):
    meal_category: Optional[str] = None
    user_confirmed_name: Optional[str] = None
    portion_description: Optional[str] = None
    ingredients: Optional[str] = None
    calories_estimate: Optional[float] = None
    protein_grams: Optional[float] = None
    carbs_grams: Optional[float] = None
    fat_grams: Optional[float] = None
    iron_mg: Optional[float] = None
    folate_mcg: Optional[float] = None
    calcium_mg: Optional[float] = None


class FoodLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    meal_category: str
    image_url: Optional[str] = None
    ai_suggested_name: Optional[str] = None
    user_confirmed_name: str
    portion_description: str
    ingredients: str
    calories_estimate: Optional[float] = None
    protein_grams: Optional[float] = None
    carbs_grams: Optional[float] = None
    fat_grams: Optional[float] = None
    iron_mg: Optional[float] = None
    folate_mcg: Optional[float] = None
    calcium_mg: Optional[float] = None
    is_ai_identified: bool
    logged_at: datetime
    created_at: datetime


class HydrationLogCreate(BaseModel):
    amount_ml: int = Field(250, ge=50, le=2000, description="Amount in milliliters")


class HydrationLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    amount_ml: int
    logged_at: datetime
    created_at: datetime


class FoodImageAnalysisResponse(BaseModel):
    suggested_name: str
    confidence: float
    ingredients: List[str]
    portion_description: str
    estimated_calories: float
    estimated_protein_g: float
    estimated_carbs_g: float
    estimated_fat_g: float
    estimated_iron_mg: float
    estimated_folate_mcg: float
    maternal_safety_note: str
    is_estimate: bool = True


class NutritionDailySummaryResponse(BaseModel):
    date_key: str
    total_calories_estimate: float
    total_protein_grams: float
    total_carbs_grams: float
    total_fat_grams: float
    total_iron_mg: float
    total_folate_mcg: float
    total_calcium_mg: float
    total_water_ml: int
    meals_logged_count: int
    nutritional_disclaimer: str = "Values are statistical dietary estimates to support healthy habits and are not verified laboratory assessments. Do not use for clinical diagnosis."
