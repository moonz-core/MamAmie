import re
import httpx
from typing import Optional, List
from app.core.config import settings
from app.schemas.ai import AIQueryResponse, AISourceCitation

# Red-flag symptoms that require immediate obstetric/emergency escalation
RED_FLAG_PATTERNS = [
    re.compile(r"\b(bleed|bleeding|blood|spotting)\b", re.IGNORECASE),
    re.compile(r"\b(severe headache|blurred vision|seeing spots|aura|flashing lights)\b", re.IGNORECASE),
    re.compile(r"\b(water broke|fluid leak|amniotic)\b", re.IGNORECASE),
    re.compile(r"\b(reduced movement|not moving|baby hasn'?t moved|less movement|no movement)\b", re.IGNORECASE),
    re.compile(r"\b(severe (abdominal|belly|stomach) pain|sharp pain|extreme cramps)\b", re.IGNORECASE),
    re.compile(r"\b(high blood pressure|preeclampsia|hypertension crisis)\b", re.IGNORECASE),
    re.compile(r"\b(chest pain|shortness of breath|difficulty breathing|faint)\b", re.IGNORECASE),
    re.compile(r"\b(high fever|chills|shivering)\b", re.IGNORECASE),
]

KNOWLEDGE_BASE = [
    {
        "keywords": ["nausea", "morning sickness", "vomit"],
        "title": "Managing Pregnancy Nausea and Morning Sickness",
        "source": "FOGSI Good Clinical Practice Guidelines on Antenatal Care",
        "summary": "Nausea is common in the 1st trimester due to rising hCG and estrogen levels.",
        "answer": (
            "Nausea and morning sickness are very common, especially during weeks 6 to 14. "
            "Helpful evidence-based strategies include: eating small, frequent meals rich in complex carbs; "
            "keeping plain crackers or nuts by your bedside; staying hydrated between meals rather than during; "
            "and trying ginger tea or lemon water. Avoid strong odors and greasy foods. "
            "If you cannot keep any liquids down for more than 24 hours, contact your doctor to evaluate for hyperemesis gravidarum."
        )
    },
    {
        "keywords": ["iron", "anemia", "folic acid", "calcium", "supplement", "vitamin"],
        "title": "Maternal Micronutrient Supplementation",
        "source": "WHO Guidelines on Nutritional Interventions during Pregnancy",
        "summary": "Essential maternal micronutrients include Folic Acid, Elemental Iron, and Calcium.",
        "answer": (
            "During pregnancy, nutritional needs increase to support fetal organ development and blood volume expansion. "
            "Folic acid (400–500 mcg daily) is recommended preconception and through the 1st trimester to support neural tube development. "
            "Iron and calcium are routinely recommended starting in the 2nd trimester by obstetricians across India. "
            "Important note: Do not take iron and calcium supplements at the exact same moment, as calcium inhibits iron absorption. "
            "Always follow your clinician's exact prescribed dosage."
        )
    },
    {
        "keywords": ["diet", "food", "eat", "nutrition", "protein", "fruit"],
        "title": "Balanced Maternal Nutrition in India",
        "source": "ICMR-National Institute of Nutrition (NIN) Dietary Guidelines",
        "summary": "A diverse diet featuring whole grains, pulses, dairy, green leafy vegetables, and seasonal fruits.",
        "answer": (
            "A balanced pregnancy diet emphasizes nutritional quality rather than 'eating for two.' "
            "Key food groups include: pulses and legumes (dal, rajma, chana, sprouts) for protein; "
            "dairy (curd, paneer, milk) for calcium and iodine; dark leafy greens (palak, methi) for folate and iron; "
            "and whole grains (millets, whole wheat, brown rice) for sustained energy. "
            "Drink plenty of clean water, and ensure all salads and vegetables are thoroughly washed."
        )
    },
    {
        "keywords": ["exercise", "walking", "yoga", "activity", "movement", "steps"],
        "title": "Safe Physical Activity in Pregnancy",
        "source": "ACOG & FOGSI Clinical Opinion on Exercise in Pregnancy",
        "summary": "Moderate, gentle movement supports cardiovascular stamina and eases pelvic discomfort.",
        "answer": (
            "Unless your doctor has advised bed rest or pelvic rest, gentle physical activity like walking (20–30 minutes daily), "
            "prenatal yoga, and pelvic floor exercises is very beneficial. "
            "It supports circulation, healthy blood pressure, mood, and sleep. "
            "Always stay well hydrated, avoid hot environments, and stop immediately if you feel dizzy, breathless, or experience cramps."
        )
    },
    {
        "keywords": ["sleep", "tired", "fatigue", "rest", "position"],
        "title": "Rest and Sleep Positions During Pregnancy",
        "source": "RCOG & WHO Maternal Wellbeing Resources",
        "summary": "Side-sleeping (especially left side) promotes optimal placental blood flow in the 2nd and 3rd trimesters.",
        "answer": (
            "Fatigue is normal in pregnancy as your body expends energy supporting your growing baby. "
            "From the second trimester onward (around week 20+), healthcare providers recommend sleeping on your side (left side is ideal) "
            "with a pillow between your knees and under your abdomen. "
            "This position prevents the weight of your uterus from pressing against the inferior vena cava, optimizing blood flow to your baby."
        )
    },
    {
        "keywords": ["breastfeeding", "lactation", "milk", "colostrum", "latch"],
        "title": "Initiation and Support of Breastfeeding",
        "source": "WHO & UNICEF Early Essential Newborn Care Guidelines",
        "summary": "Early initiation within the first hour of birth and exclusive breastfeeding for 6 months.",
        "answer": (
            "Colostrum (the initial thick, yellowish milk) provides vital antibodies and gut immunity for your newborn. "
            "Establishing a comfortable latch with the baby's mouth opened wide covering much of the lower areola prevents nipple soreness. "
            "Frequent skin-to-skin contact stimulates prolactin and oxytocin release. "
            "If you experience severe pain, engorgement, or cracked nipples, ask a certified lactation consultant or hospital midwife for hands-on guidance."
        )
    }
]


class GroundedAIService:
    async def answer_maternal_query(
        self,
        query: str,
        stage: Optional[str] = None,
        week: Optional[int] = None
    ) -> AIQueryResponse:
        # 1. Check for emergency red-flag symptoms
        for pattern in RED_FLAG_PATTERNS:
            if pattern.search(query):
                return AIQueryResponse(
                    answer=(
                        "⚠️ URGENT CLINICAL NOTICE: Based on the symptoms described in your query, "
                        "this could represent a potentially serious maternal or fetal condition that requires IMMEDIATE evaluation. "
                        "Do not wait or rely on an app for reassurance. Please contact your obstetrician, maternity hospital, "
                        "or call local emergency services immediately."
                    ),
                    is_educational_only=True,
                    safety_escalation=True,
                    emergency_notice="Seek emergency obstetric medical care without delay.",
                    citations=[
                        AISourceCitation(
                            title="Obstetric Red Flag Symptoms & Emergency Protocols",
                            source="FOGSI & Emergency Maternal Health Care Standards",
                            summary="Critical symptoms such as vaginal bleeding, fluid leakage, severe headache, vision changes, or reduced fetal movement require immediate hospital assessment."
                        )
                    ]
                )

        # 2. Retrieve grounded matching topic
        lower_q = query.lower()
        matched_topic = None
        for item in KNOWLEDGE_BASE:
            for kw in item["keywords"]:
                if kw in lower_q:
                    matched_topic = item
                    break
            if matched_topic:
                break

        if matched_topic:
            return AIQueryResponse(
                answer=matched_topic["answer"],
                is_educational_only=True,
                safety_escalation=False,
                citations=[
                    AISourceCitation(
                        title=matched_topic["title"],
                        source=matched_topic["source"],
                        summary=matched_topic["summary"]
                    )
                ]
            )

        # 3. Call External LLM (OpenAI or Gemini) if configured
        if settings.AI_PROVIDER == "openai" and settings.OPENAI_API_KEY:
            try:
                system_prompt = (
                    "You are MamAmie AI, a compassionate, medically grounded maternal wellness companion. "
                    "Support women with maternal nutrition, gentle wellbeing, preparation for labor, and newborn care. "
                    "CRITICAL SAFETY RULES: "
                    "1. NEVER prescribe medication or specify dosages. "
                    "2. NEVER make clinical diagnoses. "
                    "3. Always remind the user that this is educational guidance, not a replacement for their obstetrician or pediatrician. "
                    "4. If symptoms sound urgent, advise immediate medical consultation."
                )
                user_context = f"User is currently: {stage or 'pregnant'} (Week {week or 'unknown'}).\nQuestion: {query}"

                async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
                    resp = await client.post(
                        "https://api.openai.com/v1/chat/completions",
                        headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
                        json={
                            "model": settings.AI_MODEL_NAME or "gpt-4o-mini",
                            "messages": [
                                {"role": "system", "content": system_prompt},
                                {"role": "user", "content": user_context}
                            ],
                            "max_tokens": 400,
                            "temperature": 0.5
                        }
                    )
                    if resp.status_code == 200:
                        llm_answer = resp.json()["choices"][0]["message"]["content"]
                        return AIQueryResponse(
                            answer=llm_answer,
                            is_educational_only=True,
                            safety_escalation=False,
                            citations=[
                                AISourceCitation(
                                    title="MamAmie Grounded AI Assistant (OpenAI)",
                                    source="WHO & FOGSI Clinical Reference Standards",
                                    summary="AI generated maternal guidance aligned with obstetric safety principles."
                                )
                            ]
                        )
            except Exception:
                pass  # Fall back to evidence-based local guidance on error or timeout

        elif settings.AI_PROVIDER == "gemini" and settings.GEMINI_API_KEY:
            try:
                model_name = settings.AI_MODEL_NAME if "gemini" in settings.AI_MODEL_NAME else "gemini-1.5-flash"
                gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={settings.GEMINI_API_KEY}"
                prompt_text = (
                    "You are MamAmie AI, a maternal wellness companion. "
                    f"Context: {stage or 'pregnant'} (Week {week or 'unknown'}). "
                    "Never prescribe medicines or diagnose diseases. Provide safe, supportive educational guidance.\n\n"
                    f"User Query: {query}"
                )
                async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
                    resp = await client.post(
                        gemini_url,
                        json={"contents": [{"parts": [{"text": prompt_text}]}]}
                    )
                    if resp.status_code == 200:
                        data = resp.json()
                        llm_answer = data["candidates"][0]["content"]["parts"][0]["text"]
                        return AIQueryResponse(
                            answer=llm_answer,
                            is_educational_only=True,
                            safety_escalation=False,
                            citations=[
                                AISourceCitation(
                                    title="MamAmie Grounded AI Assistant (Gemini)",
                                    source="WHO Maternal & Child Health Guidelines",
                                    summary="AI generated maternal guidance grounded in approved clinical boundaries."
                                )
                            ]
                        )
            except Exception:
                pass  # Fall back to evidence-based local guidance on error or timeout

        # 4. Fallback educational response
        context_str = f"During {stage or 'your pregnancy journey'}"
        if week:
            context_str += f" (Week {week})"

        return AIQueryResponse(
            answer=(
                f"{context_str}, listening to your body, maintaining regular prenatal check-ups, and discussing "
                "any physical changes with your obstetrician is the safest approach. "
                "Eating fresh, wholesome meals, staying well hydrated, resting when fatigued, and taking your clinician-prescribed supplements "
                "forms the foundation of healthy maternal wellness. "
                "If you have a specific symptom or health query, you can also log it in your MamAmie journal to discuss at your next appointment."
            ),
            is_educational_only=True,
            safety_escalation=False,
            citations=[
                AISourceCitation(
                    title="Comprehensive Maternal & Child Health Framework",
                    source="Ministry of Health and Family Welfare (MoHFW) / WHO",
                    summary="Regular antenatal checkups and balanced nutrition support optimal maternal and neonatal outcomes."
                )
            ]
        )
