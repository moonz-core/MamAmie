from datetime import date, timedelta
from typing import Optional
from app.schemas.pregnancy import PregnancyCalculationResponse

WEEK_METRICS = {
    4: ("Poppy seed", "< 1 mm", "< 1 g", ["Mild cramping", "Fatigue", "Missed period"]),
    8: ("Raspberry", "~1.6 cm", "~1 g", ["Morning sickness", "Heightened sense of smell", "Frequent urination"]),
    12: ("Plum", "~5.4 cm", "~14 g", ["Restoring energy", "Skin changes", "Decreasing nausea"]),
    16: ("Avocado", "~11.6 cm", "~100 g", ["Nasal congestion", "Glowing skin", "Appetite increase"]),
    20: ("Banana", "~16.4 cm", "~300 g", ["First fetal flutters (quickening)", "Mild backache", "Heartburn"]),
    24: ("Ear of Corn", "~30 cm", "~600 g", ["Active baby kicks", "Braxton Hicks contractions", "Leg cramps"]),
    28: ("Eggplant", "~37 cm", "~1 kg", ["Mild shortness of breath", "Trouble sleeping", "Swollen ankles"]),
    32: ("Squash", "~42 cm", "~1.7 kg", ["Frequent bathroom trips", "Pelvic pressure", "Colostrum leakage"]),
    36: ("Papaya", "~47 cm", "~2.6 kg", ["Nesting instinct", "Baby descending into pelvis", "Waddling gait"]),
    40: ("Watermelon", "~51 cm", "~3.4 kg", ["Cervical effacement", "Strong contractions", "Burst of energy"]),
}


class PregnancyCalculatorService:
    @staticmethod
    def calculate_from_lmp_or_edd(
        lmp_date: Optional[date] = None,
        edd_date: Optional[date] = None,
        as_of_date: Optional[date] = None
    ) -> PregnancyCalculationResponse:
        today = as_of_date or date.today()

        if edd_date and not lmp_date:
            # Reverse calculate LMP from EDD (LMP = EDD - 280 days)
            computed_lmp = edd_date - timedelta(days=280)
            final_edd = edd_date
        elif lmp_date:
            computed_lmp = lmp_date
            final_edd = edd_date or (lmp_date + timedelta(days=280))
        else:
            # Fallback default: week 12
            computed_lmp = today - timedelta(days=84)
            final_edd = computed_lmp + timedelta(days=280)

        total_days = (today - computed_lmp).days
        total_days = max(0, min(total_days, 300))

        completed_weeks = total_days // 7
        remaining_days = total_days % 7

        days_until_edd = (final_edd - today).days

        # Trimester determination
        if completed_weeks < 14:
            trimester = 1
        elif completed_weeks < 28:
            trimester = 2
        else:
            trimester = 3

        progress_pct = round(min(100.0, max(0.0, (total_days / 280.0) * 100.0)), 1)

        # Match closest milestone metadata
        closest_week = min(WEEK_METRICS.keys(), key=lambda w: abs(w - completed_weeks))
        fruit, length, weight, symptoms = WEEK_METRICS[closest_week]

        return PregnancyCalculationResponse(
            gestational_weeks=completed_weeks,
            gestational_days=remaining_days,
            trimester=trimester,
            estimated_due_date=final_edd,
            days_until_due_date=days_until_edd,
            progress_percentage=progress_pct,
            fetal_size_comparison=f"Size of a {fruit} (approx {length})",
            fetal_weight_estimate=weight,
            fetal_length_estimate=length,
            common_symptoms=symptoms,
            is_date_estimated=(edd_date is None)
        )
