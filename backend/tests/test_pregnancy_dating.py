import pytest
from datetime import date, timedelta
from app.services.pregnancy_calculator import PregnancyCalculatorService

def test_deterministic_pregnancy_dating_week_12():
    today = date(2026, 10, 24)
    # Exactly 84 days ago = 12 weeks completed
    lmp = today - timedelta(days=84)

    calc = PregnancyCalculatorService.calculate_from_lmp_or_edd(lmp_date=lmp, as_of_date=today)
    assert calc.gestational_weeks == 12
    assert calc.gestational_days == 0
    assert calc.trimester == 1
    assert "Plum" in calc.fetal_size_comparison
    assert calc.progress_percentage == 30.0


def test_deterministic_pregnancy_dating_trimester_2_and_3():
    today = date(2026, 10, 24)
    # 20 weeks completed = 140 days
    lmp_t2 = today - timedelta(days=140)
    calc_t2 = PregnancyCalculatorService.calculate_from_lmp_or_edd(lmp_date=lmp_t2, as_of_date=today)
    assert calc_t2.gestational_weeks == 20
    assert calc_t2.trimester == 2
    assert "Banana" in calc_t2.fetal_size_comparison

    # 32 weeks completed = 224 days
    lmp_t3 = today - timedelta(days=224)
    calc_t3 = PregnancyCalculatorService.calculate_from_lmp_or_edd(lmp_date=lmp_t3, as_of_date=today)
    assert calc_t3.gestational_weeks == 32
    assert calc_t3.trimester == 3
    assert "Squash" in calc_t3.fetal_size_comparison
