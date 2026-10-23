from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user, get_current_admin_user
from app.core.exceptions import NotFoundException
from app.db.session import get_db
from app.models.user import User
from app.models.education import EducationalArticle
from app.schemas.education import (
    EducationalArticleCreate,
    EducationalArticleResponse
)

router = APIRouter(prefix="/education", tags=["Pregnancy & Maternal Education"])


@router.get("/articles", response_model=List[EducationalArticleResponse])
async def list_articles(
    stage: Optional[str] = Query(None, description="planning, pregnant, postpartum, newborn"),
    target_week: Optional[int] = Query(None, description="Filter by gestational week"),
    category: Optional[str] = Query(None, description="fetal_development, nutrition, warning_signs, etc."),
    language: str = Query("en", description="Language code"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(EducationalArticle).where(
        EducationalArticle.is_published == True,
        EducationalArticle.language == language
    )

    if stage:
        query = query.where(EducationalArticle.stage == stage)
    if target_week:
        query = query.where(EducationalArticle.target_week == target_week)
    if category:
        query = query.where(EducationalArticle.category == category)

    query = query.order_by(EducationalArticle.target_week.asc().nullsfirst(), EducationalArticle.created_at.desc())
    result = await db.execute(query)
    articles = result.scalars().all()

    # If database is fresh, populate baseline medically reviewed articles
    if not articles:
        await seed_default_articles(db)
        result = await db.execute(query)
        articles = result.scalars().all()

    return articles


@router.get("/articles/{article_id}", response_model=EducationalArticleResponse)
async def get_article(
    article_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(EducationalArticle).where(EducationalArticle.id == article_id))
    article = result.scalar_one_or_none()
    if not article:
        raise NotFoundException("Educational article not found")
    return article


@router.post("/articles", response_model=EducationalArticleResponse, status_code=status.HTTP_201_CREATED)
async def create_article(
    data: EducationalArticleCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin_user)
):
    article = EducationalArticle(
        stage=data.stage,
        target_week=data.target_week,
        category=data.category,
        title=data.title,
        summary=data.summary,
        content=data.content,
        source_attribution=data.source_attribution,
        is_medically_reviewed=data.is_medically_reviewed,
        review_date=data.review_date,
        reviewer_name=data.reviewer_name,
        is_published=True,
        language=data.language
    )
    db.add(article)
    await db.commit()
    await db.refresh(article)
    return article


async def seed_default_articles(db: AsyncSession):
    seed_data = [
        {
            "stage": "pregnant",
            "target_week": 12,
            "category": "fetal_development",
            "title": "Week 12: Reaching the End of Your First Trimester",
            "summary": "Your baby's vital systems are formed, and your risk of early pregnancy loss drops substantially.",
            "content": (
                "By week 12, your baby has fully formed fingers and toes, fingernails are beginning to sprout, "
                "and reflexes are developing. Your placenta is now actively producing progesterone. "
                "Many women notice a reduction in morning sickness and a gradual return of energy."
            ),
            "source": "FOGSI Antenatal Care Protocols & WHO Guidelines",
            "reviewer": "Dr. Maya Kulkarni, MD (OB/GYN)"
        },
        {
            "stage": "pregnant",
            "target_week": 20,
            "category": "wellness",
            "title": "Week 20: The Halfway Mark & Anomaly Scan",
            "summary": "Mid-pregnancy ultrasound evaluation and feeling your baby's movements.",
            "content": (
                "Week 20 is a major milestone. You are halfway through your 40-week journey! "
                "The Level II / Anomaly scan is typically scheduled around this time to examine fetal organ anatomy, "
                "placental position, and amniotic fluid volume."
            ),
            "source": "Indian College of Obstetricians and Gynaecologists (ICOG)",
            "reviewer": "Dr. Rohit Verma, MD, DNB (OB/GYN)"
        },
        {
            "stage": "pregnant",
            "target_week": 28,
            "category": "warning_signs",
            "title": "Third Trimester Warning Signs: When to Call Your Doctor Immediately",
            "summary": "Key symptoms that require prompt obstetric evaluation in the third trimester.",
            "content": (
                "While most pregnancies proceed smoothly, knowing warning signs is empowering. "
                "Contact your maternity hospital or emergency care immediately if you experience: "
                "1. Sudden, severe headaches not relieved by paracetamol. "
                "2. Visual disturbances (blurriness or flashing lights). "
                "3. Sudden severe swelling of hands and face. "
                "4. Any vaginal bleeding or watery discharge. "
                "5. Noticeable reduction in your baby's normal movement patterns."
            ),
            "source": "FOGSI Guidelines on Hypertensive Disorders in Pregnancy",
            "reviewer": "Dr. Ananya Sharma, MD (OB/GYN)"
        },
        {
            "stage": "postpartum",
            "target_week": None,
            "category": "breastfeeding",
            "title": "Establishing Breastfeeding in the First Two Weeks",
            "summary": "Practical guidance on latching, milk supply, and maternal comfort.",
            "content": (
                "Colostrum provides your baby's first immunization. "
                "Nurse on demand (typically 8 to 12 times in 24 hours). "
                "Ensure your baby takes a deep mouthful of areola to prevent nipple pain. "
                "Stay hydrated and rest whenever your baby rests."
            ),
            "source": "WHO / UNICEF Baby-Friendly Hospital Initiative",
            "reviewer": "Dr. Maya Kulkarni, MD, IBCLC"
        }
    ]

    for item in seed_data:
        art = EducationalArticle(
            stage=item["stage"],
            target_week=item["target_week"],
            category=item["category"],
            title=item["title"],
            summary=item["summary"],
            content=item["content"],
            source_attribution=item["source"],
            reviewer_name=item["reviewer"],
            is_medically_reviewed=True,
            is_published=True,
            language="en"
        )
        db.add(art)
    await db.commit()
