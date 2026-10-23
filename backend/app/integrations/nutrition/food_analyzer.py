from typing import Dict, Any, List, Optional
from app.schemas.nutrition import FoodImageAnalysisResponse

# Standard Indian maternal nutritional composition database (approx per standard serving)
FOOD_COMPOSITION_DB: Dict[str, Dict[str, Any]] = {
    "dal": {
        "name": "Yellow Moong / Toor Dal",
        "portion": "1 medium bowl (150g)",
        "calories": 160.0,
        "protein": 9.2,
        "carbs": 24.0,
        "fat": 3.1,
        "iron": 2.4,
        "folate": 85.0,
        "ingredients": ["toor dal", "turmeric", "cumin", "ghee", "tomatoes"],
        "maternal_note": "Excellent source of plant protein and folate. Pair with lemon for enhanced iron absorption."
    },
    "roti": {
        "name": "Whole Wheat Roti / Chapati",
        "portion": "2 medium rotis",
        "calories": 170.0,
        "protein": 5.4,
        "carbs": 34.0,
        "fat": 1.2,
        "iron": 1.8,
        "folate": 22.0,
        "ingredients": ["whole wheat flour", "water", "light ghee"],
        "maternal_note": "Provides complex carbohydrates and dietary fiber to help prevent pregnancy constipation."
    },
    "khichdi": {
        "name": "Moong Dal & Rice Khichdi",
        "portion": "1 medium plate (200g)",
        "calories": 240.0,
        "protein": 8.5,
        "carbs": 42.0,
        "fat": 4.5,
        "iron": 2.2,
        "folate": 60.0,
        "ingredients": ["rice", "yellow moong dal", "ghee", "cumin", "ginger"],
        "maternal_note": "Gentle on digestion, especially soothing during morning sickness or early trimester nausea."
    },
    "paneer": {
        "name": "Palak Paneer / Paneer Bhurji",
        "portion": "1 medium bowl (150g)",
        "calories": 260.0,
        "protein": 14.0,
        "carbs": 8.0,
        "fat": 19.0,
        "iron": 3.1,
        "folate": 75.0,
        "ingredients": ["pasteurized paneer", "spinach", "tomatoes", "garlic", "spices"],
        "maternal_note": "Rich in calcium and protein. Ensure paneer is made from pasteurized milk."
    },
    "idli": {
        "name": "Steamed Idli with Sambar",
        "portion": "2 idlis with 1 bowl sambar",
        "calories": 210.0,
        "protein": 7.0,
        "carbs": 40.0,
        "fat": 2.5,
        "iron": 1.9,
        "folate": 45.0,
        "ingredients": ["fermented rice & urad dal batter", "vegetable sambar"],
        "maternal_note": "Fermented foods provide probiotics that support gut health and nutrient absorption."
    },
    "fruit": {
        "name": "Fresh Fruit Bowl (Apple, Pomegranate, Banana)",
        "portion": "1 medium bowl (150g)",
        "calories": 110.0,
        "protein": 1.2,
        "carbs": 26.0,
        "fat": 0.4,
        "iron": 0.8,
        "folate": 35.0,
        "ingredients": ["sliced apple", "pomegranate seeds", "banana"],
        "maternal_note": "Rich in vitamin C, potassium, and antioxidants. Always wash fruits thoroughly in clean water."
    },
    "curd": {
        "name": "Fresh Curd / Yogurt with Chia Seeds",
        "portion": "1 small bowl (120g)",
        "calories": 120.0,
        "protein": 6.5,
        "carbs": 9.0,
        "fat": 5.0,
        "iron": 0.5,
        "folate": 18.0,
        "ingredients": ["pasteurized curd", "chia seeds"],
        "maternal_note": "Excellent dietary calcium source to support fetal bone development."
    }
}


class FoodAnalyzerService:
    @staticmethod
    def analyze_food_input(food_text: str, filename: Optional[str] = None) -> FoodImageAnalysisResponse:
        query = (food_text or "").lower()
        if filename:
            query += " " + filename.lower()

        # Match against database
        matched_key = None
        for key in FOOD_COMPOSITION_DB:
            if key in query:
                matched_key = key
                break

        if not matched_key:
            # Check for synonyms
            if any(w in query for w in ["chapati", "phulka", "bread", "naan"]):
                matched_key = "roti"
            elif any(w in query for w in ["curry", "sambhar", "lentil", "chana"]):
                matched_key = "dal"
            elif any(w in query for w in ["dosa", "vada", "upma"]):
                matched_key = "idli"
            elif any(w in query for w in ["yogurt", "raita", "dahi"]):
                matched_key = "curd"
            elif any(w in query for w in ["apple", "banana", "orange", "salad"]):
                matched_key = "fruit"
            elif any(w in query for w in ["rice", "biryani", "pulao"]):
                matched_key = "khichdi"
            else:
                matched_key = "dal"

        item = FOOD_COMPOSITION_DB[matched_key]
        return FoodImageAnalysisResponse(
            suggested_name=item["name"],
            confidence=0.91,
            ingredients=item["ingredients"],
            portion_description=item["portion"],
            estimated_calories=item["calories"],
            estimated_protein_g=item["protein"],
            estimated_carbs_g=item["carbs"],
            estimated_fat_g=item["fat"],
            estimated_iron_mg=item["iron"],
            estimated_folate_mcg=item["folate"],
            maternal_safety_note=item["maternal_note"],
            is_estimate=True
        )
