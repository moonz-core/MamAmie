"""
Database Seeding Script for MamAmie AI
Initializes the database with:
1. Medically reviewed educational content (Weeks 1-40, Postpartum, Newborn care)
2. A demo maternal profile with appointments, planner entries, and medications
"""
import sys
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

import asyncio
from datetime import date, datetime, timedelta, timezone
from sqlalchemy import select
from app.db.session import async_session_factory, init_db
from app.core.security import get_password_hash
from app.models.user import User, UserProfile, ConsentRecord
from app.models.pregnancy import PregnancyJourney, PregnancyMilestone
from app.models.education import EducationalArticle
from app.models.planner import PlannerEntry
from app.models.appointment import Appointment
from app.models.medication import Medication, DoseLog
from app.models.newborn import NewbornProfile, VaccinationRecord
from app.services.pregnancy_calculator import PregnancyCalculatorService
from app.services.vaccination_scheduler import VaccinationSchedulerService


EDUCATIONAL_SEED_ARTICLES = [
    {
        "stage": "pregnant",
        "target_week": 4,
        "category": "fetal_development",
        "title": "Week 4: The Blastocyst Implants",
        "summary": "Your baby is the size of a poppy seed. The blastocyst is implanting into the uterine lining.",
        "content": "At Week 4, the blastocyst has reached your uterus and begins implanting into the endometrium. The amniotic sac and placenta are forming to nourish your baby. Start taking 400-800 mcg of folic acid daily to support neural tube development.",
        "source_attribution": "WHO Maternal Care Guidelines",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Ananya Sharma, MD (OB/GYN)",
    },
    {
        "stage": "pregnant",
        "target_week": 8,
        "category": "fetal_development",
        "title": "Week 8: Tiny Fingers and Toes",
        "summary": "Your baby is the size of a raspberry. Webbed fingers and toes are developing.",
        "content": "At 8 weeks, all major organs have begun to form. Tiny fingers and toes are branching out. The embryonic tail is nearly gone, and facial features like the tip of the nose and eyelids are becoming distinct. Common symptoms include morning sickness and fatigue.",
        "source_attribution": "FOGSI Clinical Guidelines",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Ananya Sharma, MD (OB/GYN)",
    },
    {
        "stage": "pregnant",
        "target_week": 12,
        "category": "wellness",
        "title": "Week 12: End of the First Trimester",
        "summary": "Your baby is the size of a plum. Risk of early miscarriage drops significantly.",
        "content": "Congratulations on completing the first trimester! Your baby's kidneys are producing urine and vocal cords are forming. You may schedule your first trimester screening (NT ultrasound). Energy levels often start improving as hCG levels stabilize.",
        "source_attribution": "ACOG & FOGSI Prenatal Standards",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Rajesh K. Patel, MD (OB/GYN)",
    },
    {
        "stage": "pregnant",
        "target_week": 20,
        "category": "fetal_development",
        "title": "Week 20: The Anatomy Scan & Quickening",
        "summary": "Your baby is the size of a banana. You may feel gentle flutter movements.",
        "content": "You are halfway through your pregnancy! Between weeks 18 and 22, clinicians perform the mid-pregnancy anatomy scan (anomaly scan) to check organs, limbs, and placental location. Fetal flutter movements ('quickening') become noticeable.",
        "source_attribution": "FOGSI Sonography Guidelines",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Rajesh K. Patel, MD (OB/GYN)",
    },
    {
        "stage": "pregnant",
        "target_week": 28,
        "category": "warning_signs",
        "title": "Week 28: Third Trimester & Warning Signs",
        "summary": "Your baby is the size of an eggplant. Pay attention to fetal kick counts.",
        "content": "Welcome to the third trimester! Track your baby's kick counts daily: you should feel at least 10 kicks within 2 hours of quiet rest. Red-flag symptoms that require immediate emergency care include vaginal bleeding, sudden severe headache, blurred vision, or decreased fetal movement.",
        "source_attribution": "WHO Essential Antenatal Care",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Ananya Sharma, MD (OB/GYN)",
    },
    {
        "stage": "postpartum",
        "target_week": None,
        "category": "breastfeeding",
        "title": "Postpartum: Establishing Successful Lactation",
        "summary": "Understanding colostrum, mature milk transition, and latch mechanics.",
        "content": "During the first 2-4 days postpartum, your breasts produce colostrum, rich in antibodies and protein. Frequent skin-to-skin contact and nursing on demand help establish mature milk supply. Ensure baby's chin touches your breast and lips flare outward like a fish.",
        "source_attribution": "UNICEF & WHO Breastfeeding Counseling",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Priya Nair, MD (Pediatrics & Lactation)",
    },
    {
        "stage": "newborn",
        "target_week": None,
        "category": "wellness",
        "title": "Newborn Care: Umbilical Cord & Safe Sleep",
        "summary": "Cord care guidelines and ABC safe sleep rules to prevent SIDS.",
        "content": "Keep the umbilical cord stump dry and clean; do not apply powders or oils. Always follow the ABC safe sleep rules: Alone, on their Back, in an empty Crib or bassinet with a firm mattress. Avoid soft pillows, quilts, or bumpers in the sleeping area.",
        "source_attribution": "Indian Academy of Pediatrics (IAP)",
        "is_medically_reviewed": True,
        "reviewer_name": "Dr. Priya Nair, MD (Pediatrics)",
    }
]


async def seed_database():
    print("Initializing database tables...")
    await init_db()

    async with async_session_factory() as session:
        # 1. Seed Educational Articles
        print("Seeding educational content...")
        for art_data in EDUCATIONAL_SEED_ARTICLES:
            existing = await session.execute(
                select(EducationalArticle).where(EducationalArticle.title == art_data["title"])
            )
            if not existing.scalar_one_or_none():
                article = EducationalArticle(
                    stage=art_data["stage"],
                    target_week=art_data.get("target_week"),
                    category=art_data["category"],
                    title=art_data["title"],
                    summary=art_data["summary"],
                    content=art_data["content"],
                    source_attribution=art_data["source_attribution"],
                    is_medically_reviewed=art_data["is_medically_reviewed"],
                    reviewer_name=art_data.get("reviewer_name"),
                    review_date=date.today(),
                    version=1,
                    is_published=True,
                    language="en",
                )
                session.add(article)

        # 2. Seed Demo User
        demo_email = "demo@mamamie.app"
        existing_user = await session.execute(select(User).where(User.email == demo_email))
        user = existing_user.scalar_one_or_none()

        if not user:
            print("Creating demo maternal user account (demo@mamamie.app)...")
            user = User(
                email=demo_email,
                hashed_password=get_password_hash("MamAmie123!"),
                full_name="Pooja Sharma",
                phone_number="+919876543210",
                is_active=True,
                is_verified=True,
                role="user",
            )
            session.add(user)
            await session.flush()

            # Profile
            profile = UserProfile(
                user_id=user.id,
                current_stage="pregnant",
                language_code="en",
                timezone="Asia/Kolkata",
                diet_preferences={"type": "vegetarian", "supplement_friendly": True},
                food_allergies=["peanuts"],
                notification_preferences={"medications": True, "appointments": True, "hydration": True},
                clinician_notes="Dr. Sen recommended checking hemoglobin levels at next visit.",
                is_onboarding_completed=True,
            )
            session.add(profile)

            # Consent
            consent = ConsentRecord(
                user_id=user.id,
                consent_type="health_data_processing",
                granted=True,
                notes="Standard onboarding consent accepted",
            )
            session.add(consent)

            # Pregnancy Journey (16 weeks pregnant)
            lmp = date.today() - timedelta(weeks=16)
            calc = PregnancyCalculatorService.calculate_from_lmp_or_edd(lmp_date=lmp)
            journey = PregnancyJourney(
                user_id=user.id,
                lmp_date=lmp,
                edd_date=calc.estimated_due_date,
                is_active=True,
                status="ongoing",
            )
            session.add(journey)
            await session.flush()

            # Pregnancy Milestones
            m1 = PregnancyMilestone(
                journey_id=journey.id,
                week_number=12,
                title="First Trimester NT Scan",
                description="Check nuchal translucency and early nasal bone.",
                is_completed=True,
                completed_at=datetime.now(timezone.utc) - timedelta(weeks=4),
            )
            m2 = PregnancyMilestone(
                journey_id=journey.id,
                week_number=20,
                title="Mid-Pregnancy Anatomy Scan",
                description="Comprehensive structural ultrasound.",
                is_completed=False,
            )
            session.add_all([m1, m2])

            # Medications
            med1 = Medication(
                user_id=user.id,
                name="Folic Acid + Methylcobalamin",
                dose="5",
                unit="mg",
                schedule_type="daily",
                time_minutes=9 * 60,  # 09:00 AM
                instructions="Take with breakfast",
                is_supplement=True,
                clinician_confirmed=True,
                is_active=True,
            )
            med2 = Medication(
                user_id=user.id,
                name="Ferrous Ascorbate (Iron)",
                dose="100",
                unit="mg",
                schedule_type="daily",
                time_minutes=20 * 60,  # 08:00 PM
                instructions="Avoid taking with milk; take with orange juice or water",
                is_supplement=True,
                clinician_confirmed=True,
                is_active=True,
            )
            session.add_all([med1, med2])
            await session.flush()

            # Dose Logs
            dlog = DoseLog(
                medication_id=med1.id,
                user_id=user.id,
                scheduled_date=date.today(),
                status="taken",
                taken_at=datetime.now(timezone.utc),
            )
            session.add(dlog)

            # Appointment
            app1 = Appointment(
                user_id=user.id,
                title="Second Trimester Routine Checkup",
                clinician_or_clinic="Dr. Meera Sen, Apollo Clinic",
                location="Koramangala, Bengaluru",
                scheduled_date=date.today() + timedelta(days=5),
                scheduled_time_minutes=10 * 60 + 30,  # 10:30 AM
                questions="Discuss mild backache and iron supplement brand tolerance.",
                status="planned",
                notes="Bring latest CBC lab report.",
            )
            session.add(app1)

            # Planner Entries
            today_str = date.today().isoformat()
            p1 = PlannerEntry(
                user_id=user.id,
                title="Morning Prenatal Walk & Hydration",
                category="task",
                day_key=today_str,
                time_minutes=7 * 60,
                notes="Light 20-minute walk in fresh air.",
                is_completed=True,
            )
            p2 = PlannerEntry(
                user_id=user.id,
                title="Take Iron & Vitamin C",
                category="medication",
                day_key=today_str,
                time_minutes=20 * 60,
                notes="With lemon water after dinner.",
                is_completed=False,
            )
            session.add_all([p1, p2])

        await session.commit()
        print("Database successfully seeded with clinical articles and demo profile!")


if __name__ == "__main__":
    asyncio.run(seed_database())
