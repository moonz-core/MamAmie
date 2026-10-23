from datetime import date, timedelta
from typing import List, Dict, Any

STANDARD_INDIAN_UIP_SCHEDULE = [
    {"name": "BCG (Tuberculosis)", "weeks": 0, "notes": "Administered at birth or as early as possible within the first year."},
    {"name": "Hepatitis B (Birth Dose)", "weeks": 0, "notes": "Must be administered within 24 hours of birth."},
    {"name": "OPV 0 (Oral Polio)", "weeks": 0, "notes": "Administered at birth or within the first 15 days."},
    {"name": "Pentavalent 1 (DTP-HepB-Hib)", "weeks": 6, "notes": "Protects against Diphtheria, Pertussis, Tetanus, Hep B, and Hib pneumonia/meningitis."},
    {"name": "Rotavirus 1", "weeks": 6, "notes": "Protects against severe rotavirus diarrhea."},
    {"name": "fIPV 1 & PCV 1", "weeks": 6, "notes": "Fractional Inactivated Polio & Pneumococcal Conjugate Vaccine."},
    {"name": "Pentavalent 2", "weeks": 10, "notes": "Second dose of combination vaccine."},
    {"name": "Rotavirus 2 & OPV 1", "weeks": 10, "notes": "Oral rotavirus and polio boosters."},
    {"name": "Pentavalent 3", "weeks": 14, "notes": "Third dose of combination vaccine."},
    {"name": "Rotavirus 3 & PCV 2", "weeks": 14, "notes": "Third oral rotavirus and second PCV dose."},
    {"name": "MR 1 (Measles & Rubella)", "weeks": 36, "notes": "Administered between 9 to 12 months with Vitamin A 1st dose."},
    {"name": "PCV Booster", "weeks": 36, "notes": "Pneumococcal booster administered at 9 completed months."},
]


class VaccinationSchedulerService:
    @staticmethod
    def generate_schedule(birth_date: date) -> List[Dict[str, Any]]:
        records = []
        for item in STANDARD_INDIAN_UIP_SCHEDULE:
            due = birth_date + timedelta(weeks=item["weeks"])
            records.append({
                "vaccine_name": item["name"],
                "due_age_weeks": item["weeks"],
                "due_date": due,
                "status": "scheduled",
                "notes": item["notes"]
            })
        return records
