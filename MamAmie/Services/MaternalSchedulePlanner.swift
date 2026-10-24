import Foundation

// MARK: - Maternal Clinical Milestone Definition

struct MaternalClinicalMilestone: Identifiable, Codable, Equatable {
    let id: String
    let weekNumber: Int
    let title: String
    let category: EntryCategory
    let clinicalPurpose: String
    let questionsForDoctor: [String]
    let isSonography: Bool
    let isBloodTest: Bool
    let isHospitalVisit: Bool
    let defaultTimeMinutes: Int // Minutes after midnight (e.g., 600 = 10:00 AM)
    let allowableWeekWindow: ClosedRange<Int>
    let conditionTags: [String]
    var recurrenceWeeks: Int? = nil

    init(
        id: String,
        weekNumber: Int,
        title: String,
        category: EntryCategory,
        clinicalPurpose: String,
        questionsForDoctor: [String],
        isSonography: Bool,
        isBloodTest: Bool,
        isHospitalVisit: Bool,
        defaultTimeMinutes: Int,
        allowableWeekWindow: ClosedRange<Int>,
        conditionTags: [String],
        recurrenceWeeks: Int? = nil
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.title = title
        self.category = category
        self.clinicalPurpose = clinicalPurpose
        self.questionsForDoctor = questionsForDoctor
        self.isSonography = isSonography
        self.isBloodTest = isBloodTest
        self.isHospitalVisit = isHospitalVisit
        self.defaultTimeMinutes = defaultTimeMinutes
        self.allowableWeekWindow = allowableWeekWindow
        self.conditionTags = conditionTags
        self.recurrenceWeeks = recurrenceWeeks
    }
}

// MARK: - Maternal Schedule Planner Service

final class MaternalSchedulePlanner {
    static let shared = MaternalSchedulePlanner()

    private let userDefaultsKey = "mamamie_last_planned_profile_signature"

    // MARK: - Clinical Milestones Database (ACOG & WHO Standard of Care)

    static let allMilestones: [MaternalClinicalMilestone] = [
        // MARK: First Trimester (Weeks 1 - 13)
        MaternalClinicalMilestone(
            id: "maternal_week_08_dating_scan",
            weekNumber: 8,
            title: "First Trimester Dating & Viability Sonography Scan",
            category: .test,
            clinicalPurpose: "Confirm viable intrauterine pregnancy, detect embryonic cardiac activity (heartbeat), measure Crown-Rump Length (CRL), and confirm clinical Estimated Due Date (EDD).",
            questionsForDoctor: [
                "Is the gestational sac and fetal heartbeat developing normally?",
                "Does the crown-rump length measurement match my calculated due date?"
            ],
            isSonography: true,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 570, // 9:30 AM
            allowableWeekWindow: 6...10,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_08_first_ob_visit",
            weekNumber: 8,
            title: "Initial Comprehensive Prenatal Consultation",
            category: .appointment,
            clinicalPurpose: "Baseline maternal blood pressure, medical and obstetric history review, prenatal vitamins check (folic acid, iron), and establishing emergency contact protocols.",
            questionsForDoctor: [
                "Are my current prenatal vitamins and medications safe?",
                "Which local hospital or birth center are you affiliated with?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630, // 10:30 AM
            allowableWeekWindow: 6...10,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_10_blood_panel",
            weekNumber: 10,
            title: "First Trimester Baseline Blood Panel & Urinalysis",
            category: .test,
            clinicalPurpose: "CBC (anemia screening), Blood Group & Rh Factor typing, Rubella immunity, Hepatitis B, HIV, Syphilis screening, and urine culture to detect asymptomatic bacteriuria.",
            questionsForDoctor: [
                "What is my blood type and Rh factor status?",
                "Are my iron and hemoglobin levels within normal range?"
            ],
            isSonography: false,
            isBloodTest: true,
            isHospitalVisit: true,
            defaultTimeMinutes: 540, // 9:00 AM
            allowableWeekWindow: 8...12,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_12_nt_scan",
            weekNumber: 12,
            title: "Nuchal Translucency (NT) & Early Anatomy Sonography Scan",
            category: .test,
            clinicalPurpose: "High-precision ultrasound measuring fluid behind baby's neck (NT) to screen for Down syndrome (Trisomy 21), Trisomy 18, and early structural heart formation.",
            questionsForDoctor: [
                "Is the nuchal translucency measurement within the normal threshold (<3mm)?",
                "Did you observe the nasal bone and early cranial structures?"
            ],
            isSonography: true,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 600, // 10:00 AM
            allowableWeekWindow: 11...13,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_12_prenatal_visit",
            weekNumber: 12,
            title: "Routine 12-Week Prenatal Checkup",
            category: .appointment,
            clinicalPurpose: "First Doppler listen for fetal heart tones (120-160 bpm), review of blood panel and NT sonogram results, maternal weight and blood pressure assessment.",
            questionsForDoctor: [
                "Can we listen to the baby's heartbeat on Doppler today?",
                "How are my baseline blood panel results looking?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 660, // 11:00 AM
            allowableWeekWindow: 11...14,
            conditionTags: []
        ),

        // MARK: Second Trimester (Weeks 14 - 27)
        MaternalClinicalMilestone(
            id: "maternal_week_16_quad_screen",
            weekNumber: 16,
            title: "Second Trimester Quad Marker Screen (MSAFP)",
            category: .test,
            clinicalPurpose: "Maternal serum alpha-fetoprotein (MSAFP), hCG, estriol, and inhibin-A blood test screening for neural tube defects (spina bifida) and abdominal wall defects.",
            questionsForDoctor: [
                "Does my MSAFP result indicate healthy neural tube development?"
            ],
            isSonography: false,
            isBloodTest: true,
            isHospitalVisit: true,
            defaultTimeMinutes: 570,
            allowableWeekWindow: 15...18,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_16_prenatal_visit",
            weekNumber: 16,
            title: "Routine 16-Week Prenatal Visit",
            category: .appointment,
            clinicalPurpose: "Fundal height check, Doppler fetal heart rate, maternal blood pressure surveillance, and discussing initial fetal movement ('quickening').",
            questionsForDoctor: [
                "When should I expect to feel baby's first light kicks or flutters?",
                "What stretches can help ease lower back and round ligament discomfort?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 15...18,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_20_anatomy_scan",
            weekNumber: 20,
            title: "Comprehensive Fetal Anatomy Scan (Level II Sonography)",
            category: .test,
            clinicalPurpose: "The definitive mid-pregnancy ultrasound: meticulous evaluation of brain chambers, 4-chamber heart, spine, kidneys, limbs, facial profile, placental position, and amniotic fluid volume.",
            questionsForDoctor: [
                "Are all organs, heart chambers, and spine developing symmetrically?",
                "Where is the placenta located (is it safely away from the cervix)?",
                "Is the amniotic fluid level normal?"
            ],
            isSonography: true,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 570, // 9:30 AM
            allowableWeekWindow: 18...22,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_20_mid_review",
            weekNumber: 20,
            title: "Mid-Pregnancy Doctor Consultation",
            category: .appointment,
            clinicalPurpose: "Detailed review of Level II sonography findings, measuring fundal height (pubic bone to top of uterus), checking maternal swelling and blood pressure.",
            questionsForDoctor: [
                "Are there any anatomical findings that need follow-up?",
                "How is my uterine fundal height tracking relative to week 20?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 645,
            allowableWeekWindow: 19...22,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_24_prenatal_visit",
            weekNumber: 24,
            title: "Routine 24-Week Prenatal Visit",
            category: .appointment,
            clinicalPurpose: "Fetal viability milestone, fundal height tracking, fetal activity verification, pre-eclampsia screening, and receiving preparation instructions for glucose screening.",
            questionsForDoctor: [
                "How should I prepare for next month's glucose screening test?",
                "What pattern of baby movements is typical at this stage?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 23...25,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_26_glucose_screen",
            weekNumber: 26,
            title: "Gestational Diabetes Glucose Screen (1-Hr OGTT) & CBC",
            category: .test,
            clinicalPurpose: "50g oral glucose challenge test to screen for Gestational Diabetes Mellitus (GDM) + repeat CBC to catch second-trimester physiological anemia.",
            questionsForDoctor: [
                "What is my 1-hour glucose test reading (normal is typically under 140 mg/dL)?",
                "Do my iron levels show any signs of maternal anemia?"
            ],
            isSonography: false,
            isBloodTest: true,
            isHospitalVisit: true,
            defaultTimeMinutes: 540,
            allowableWeekWindow: 24...28,
            conditionTags: []
        ),

        // MARK: Third Trimester (Weeks 28 - 40)
        MaternalClinicalMilestone(
            id: "maternal_week_28_prenatal_visit",
            weekNumber: 28,
            title: "Third Trimester Transition Prenatal Visit",
            category: .appointment,
            clinicalPurpose: "Transitioning to bi-weekly prenatal appointments! Review glucose screening results, start daily fetal kick counts (10 kicks in 2 hours), check edema and blood pressure.",
            questionsForDoctor: [
                "How should I properly track daily kick counts?",
                "Are my glucose and iron test results completely clear?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 27...29,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_28_tdap_rhogam",
            weekNumber: 28,
            title: "Maternal Tdap Vaccination & Rhogam Prophylaxis (if indicated)",
            category: .test,
            clinicalPurpose: "Tdap vaccination stimulates maternal antibodies that cross the placenta to safeguard your newborn against pertussis (whooping cough). Rhogam administered if mother is Rh-negative.",
            questionsForDoctor: [
                "Will I receive the Tdap booster today to protect baby after birth?",
                "Do I require Rhogam anti-D prophylaxis based on my blood type?"
            ],
            isSonography: false,
            isBloodTest: true,
            isHospitalVisit: true,
            defaultTimeMinutes: 660,
            allowableWeekWindow: 27...36,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_30_prenatal_visit",
            weekNumber: 30,
            title: "Routine 30-Week Prenatal Checkup",
            category: .appointment,
            clinicalPurpose: "Bi-weekly visit: maternal blood pressure surveillance, urine dipstick for protein/glucose, fundal height tracking, and reviewing comfortable left-side sleeping positions.",
            questionsForDoctor: [
                "Is my fundal growth matching 30 centimeters?",
                "What signs of pre-eclampsia should I watch for at home?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 29...31,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_32_growth_scan",
            weekNumber: 32,
            title: "Third Trimester Fetal Growth & Wellbeing Sonography Scan",
            category: .test,
            clinicalPurpose: "Sonographic assessment of fetal growth velocity, estimated fetal weight (EFW), amniotic fluid index (AFI), and fetal presentation (cephalic head-down vs breech).",
            questionsForDoctor: [
                "What is baby's estimated fetal weight and growth percentile?",
                "Is baby in a head-down (cephalic) presentation?",
                "Is the amniotic fluid volume healthy?"
            ],
            isSonography: true,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 570,
            allowableWeekWindow: 30...34,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_32_prenatal_visit",
            weekNumber: 32,
            title: "Routine 32-Week Prenatal Visit",
            category: .appointment,
            clinicalPurpose: "Review 32-week growth sonogram, fetal lie and presentation, review pre-term labor warning signs (regular contractions, fluid leaks, bleeding).",
            questionsForDoctor: [
                "Did the growth scan confirm healthy development?",
                "What contraction frequency should prompt me to call the labor ward?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 645,
            allowableWeekWindow: 31...33,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_34_prenatal_visit",
            weekNumber: 34,
            title: "Routine 34-Week Prenatal Visit & Birth Plan Review",
            category: .appointment,
            clinicalPurpose: "Evaluate fetal presentation (head-down verification), discuss labor pain management options (epidural, nitrous oxide, natural), and finalize hospital admission documents.",
            questionsForDoctor: [
                "Is baby's head positioned down toward the pelvis?",
                "Can we review my preferences for my birth plan and labor pain relief?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 33...35,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_36_gbs_swab",
            weekNumber: 36,
            title: "Group B Streptococcus (GBS) Screening Swab",
            category: .test,
            clinicalPurpose: "Gentle vaginal-rectal culture swab screening for Group B Strep bacteria. If positive, simple IV antibiotics during active labor completely protect baby from transmission.",
            questionsForDoctor: [
                "How will I receive the results of my GBS culture test?",
                "What is the protocol during labor if my GBS swab is positive?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 570,
            allowableWeekWindow: 35...37,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_36_prenatal_visit",
            weekNumber: 36,
            title: "36-Week Prenatal Visit (Weekly Visits Begin)",
            category: .appointment,
            clinicalPurpose: "Weekly checkups start now! Verify fetal station and head engagement, check maternal blood pressure, and ensure hospital bag and car seat are prepared.",
            questionsForDoctor: [
                "Has baby's head dropped deeper into the pelvis (lightening)?",
                "At what point in contraction frequency should I leave for the hospital?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 35...37,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_37_full_term_visit",
            weekNumber: 37,
            title: "37-Week Full Term Prenatal Checkup",
            category: .appointment,
            clinicalPurpose: "Congratulations on reaching early full term! Cervical readiness check (dilation and effacement if indicated), fetal heart tones, and reviewing water breaking instructions.",
            questionsForDoctor: [
                "Are there signs of cervical thinning (effacement) or dilation?",
                "What should I do immediately if my water breaks before contractions start?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 36...38,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_38_prenatal_visit",
            weekNumber: 38,
            title: "38-Week Prenatal Checkup",
            category: .appointment,
            clinicalPurpose: "Weekly surveillance: maternal blood pressure, urine protein check, fetal heart rate monitoring, and reviewing the 5-1-1 contraction rule.",
            questionsForDoctor: [
                "Is baby continuing to show strong movement patterns?",
                "Can you confirm our hospital triage telephone number once more?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 37...39,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_39_prenatal_visit",
            weekNumber: 39,
            title: "39-Week Prenatal Checkup",
            category: .appointment,
            clinicalPurpose: "Weekly evaluation: checking cervical readiness, fetal head station, discussion of spontaneous labor signs, and natural labor readiness techniques.",
            questionsForDoctor: [
                "What is baby's station relative to my ischial spines?",
                "What natural techniques are safe to encourage labor progression?"
            ],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 630,
            allowableWeekWindow: 38...40,
            conditionTags: []
        ),
        MaternalClinicalMilestone(
            id: "maternal_week_40_due_date_visit",
            weekNumber: 40,
            title: "Due Date Consultation & Fetal Surveillance (NST)",
            category: .appointment,
            clinicalPurpose: "Happy Due Date! Non-Stress Test (NST) and Biophysical Profile (BPP) ultrasound if needed to evaluate amniotic fluid and fetal wellbeing if labor has not started yet.",
            questionsForDoctor: [
                "How is baby's heart rate responding to movements on the NST monitor?",
                "What is our post-dates monitoring plan for the coming days?"
            ],
            isSonography: true,
            isBloodTest: false,
            isHospitalVisit: true,
            defaultTimeMinutes: 600,
            allowableWeekWindow: 39...41,
            conditionTags: []
        )
    ]

    // MARK: - Optional Wellness, Movement & Daily Habit Milestones

    static let wellnessMilestones: [MaternalClinicalMilestone] = [
        MaternalClinicalMilestone(
            id: "maternal_wellness_walking",
            weekNumber: 12,
            title: "Daily Gentle Prenatal Walking Routine (20–30 min)",
            category: .task,
            clinicalPurpose: "ACOG recommends 150 minutes of moderate activity weekly. Regular walking stimulates pelvic blood flow, manages blood glucose, improves sleep, and eases lower back tension.",
            questionsForDoctor: ["Are there any heart rate or exertion limits I should follow for walking?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 480, // 8:00 AM
            allowableWeekWindow: 4...41,
            conditionTags: ["walking"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_yoga",
            weekNumber: 10,
            title: "Weekly Prenatal Yoga & Hip-Opening Stretches",
            category: .task,
            clinicalPurpose: "Gentle Cat-Cow, Malasana deep squats, and butterfly stretches to loosen pelvic ligaments, maintain flexibility, and encourage optimal anterior fetal positioning.",
            questionsForDoctor: ["Which stretching poses are best for easing my round ligament tension?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 600, // 10:00 AM
            allowableWeekWindow: 8...41,
            conditionTags: ["yoga"],
            recurrenceWeeks: 1
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_vit_d",
            weekNumber: 13,
            title: "Bi-Weekly Morning Sunlight & Vitamin D Routine (15–20 min)",
            category: .task,
            clinicalPurpose: "Natural sunlight stimulates endogenous Vitamin D synthesis, essential for fetal bone and tooth mineralization and balancing maternal circadian rhythms.",
            questionsForDoctor: ["Should I have my serum 25-hydroxyvitamin D levels tested alongside routine labs?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 510, // 8:30 AM
            allowableWeekWindow: 4...41,
            conditionTags: ["sunlight"],
            recurrenceWeeks: 2
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_hydration",
            weekNumber: 14,
            title: "Daily Hydration & Electrolyte Target (2.5 Liters)",
            category: .task,
            clinicalPurpose: "Ensures healthy amniotic fluid volume, supports 45% maternal blood volume expansion, and prevents dehydration-induced Braxton Hicks contractions.",
            questionsForDoctor: ["How much water and electrolyte intake do you recommend for my stage?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 540, // 9:00 AM
            allowableWeekWindow: 4...41,
            conditionTags: ["hydration"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_magnesium",
            weekNumber: 16,
            title: "Warm Magnesium (Epsom Salt) Soak for Leg Cramps",
            category: .task,
            clinicalPurpose: "A soothing warm magnesium soak relaxes tense calf muscles and arches, relieving nighttime leg cramps (charley horses) and ease sacroiliac joint discomfort.",
            questionsForDoctor: ["Are warm magnesium foot soaks completely safe for my pregnancy stage?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1230, // 8:30 PM
            allowableWeekWindow: 14...41,
            conditionTags: ["magnesium"],
            recurrenceWeeks: 2
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_kegels",
            weekNumber: 18,
            title: "Daily Pelvic Floor (Kegel) & Gentle Core Care",
            category: .task,
            clinicalPurpose: "Gentle pelvic floor contractions (3 sets of 10 daily) to support bladder control, enhance pelvic floor endurance for labor, and accelerate postpartum recovery.",
            questionsForDoctor: ["Can you verify that I am contracting the correct pelvic floor muscles?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1140, // 7:00 PM
            allowableWeekWindow: 12...41,
            conditionTags: ["kegels"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_side_sleep",
            weekNumber: 20,
            title: "Left-Side Sleeping Posture & Pillow Alignment Check",
            category: .task,
            clinicalPurpose: "ACOG guideline: sleeping on the left side with a supportive knee pillow keeps the heavy uterus from compressing the inferior vena cava, optimizing placental blood flow.",
            questionsForDoctor: ["What pillow placement do you recommend to alleviate hip and lower back pain during sleep?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1320, // 10:00 PM
            allowableWeekWindow: 18...41,
            conditionTags: ["sleep"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_leg_elevation",
            weekNumber: 24,
            title: "15-Minute Leg Elevation for Swelling Relief",
            category: .task,
            clinicalPurpose: "Resting with feet elevated above heart level facilitates venous return, relieves fluid pooling in the feet and ankles, and prevents varicose vein strain.",
            questionsForDoctor: ["Is my ankle swelling within expected physiological limits?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1020, // 5:00 PM
            allowableWeekWindow: 20...41,
            conditionTags: ["swelling"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_kick_counts",
            weekNumber: 28,
            title: "Daily Fetal Kick Counting Session (10 movements in 2h)",
            category: .task,
            clinicalPurpose: "ACOG standard third-trimester monitoring: count 10 distinct fetal movements (kicks, rolls, flutters) during baby's active window each evening.",
            questionsForDoctor: ["What should I do if I notice a noticeable decrease in movement patterns?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1200, // 8:00 PM
            allowableWeekWindow: 28...41,
            conditionTags: ["kick_counts"]
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_perineal_massage",
            weekNumber: 34,
            title: "Bi-Weekly Perineal Massage & Labor Prep Stretching",
            category: .task,
            clinicalPurpose: "Gentle perineal massage starting at 34-35 weeks increases tissue elasticity and reduces the risk of perineal tears during vaginal delivery.",
            questionsForDoctor: ["Do you recommend perineal massage with sweet almond or olive oil?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 1260, // 9:00 PM
            allowableWeekWindow: 34...41,
            conditionTags: ["labor_prep"],
            recurrenceWeeks: 2
        ),
        MaternalClinicalMilestone(
            id: "maternal_wellness_hospital_bag",
            weekNumber: 35,
            title: "Pack Hospital Bag & Newborn Essentials",
            category: .task,
            clinicalPurpose: "Prepare labor comfort items, infant car seat, maternity medical records, postpartum supplies, and baby's homecoming outfit.",
            questionsForDoctor: ["What specific documentation or supplies does your maternity ward require upon arrival?"],
            isSonography: false,
            isBloodTest: false,
            isHospitalVisit: false,
            defaultTimeMinutes: 600, // 10:00 AM
            allowableWeekWindow: 34...38,
            conditionTags: ["hospital_bag"]
        )
    ]

    // MARK: - Schedule Generator

    func generateEntries(for profile: OnboardingProfile) -> [CalendarEntry] {
        guard profile.stage == .pregnant else {
            return generateNonPregnantEntries(for: profile)
        }

        let calendar = LocalDay.calendar
        let dueDate: Date

        if let explicitDue = profile.estimatedDueDate {
            dueDate = explicitDue
        } else if let lmp = profile.lastPeriodDate {
            dueDate = calendar.date(byAdding: .day, value: 280, to: lmp) ?? Date()
        } else {
            // Default 40-week timeline assuming currently at week 12
            dueDate = calendar.date(byAdding: .day, value: 196, to: Date()) ?? Date()
        }

        // Gestational start date (Day 0 of pregnancy / LMP equivalent) = Due Date - 280 days
        guard let pregnancyStartDate = calendar.date(byAdding: .day, value: -280, to: dueDate) else {
            return []
        }

        var entries: [CalendarEntry] = []
        let now = Date()

        // Combine clinical care milestones and optional wellness routines
        let combinedMilestones = Self.allMilestones + Self.wellnessMilestones

        for milestone in combinedMilestones {
            let weeksToSchedule: [Int]
            if let recurrence = milestone.recurrenceWeeks, recurrence > 0 {
                weeksToSchedule = stride(from: milestone.allowableWeekWindow.lowerBound, through: milestone.allowableWeekWindow.upperBound, by: recurrence).map { $0 }
            } else {
                weeksToSchedule = [milestone.weekNumber]
            }

            for weekNum in weeksToSchedule {
                // Calculate target date: pregnancyStartDate + (weekNum * 7) days
                guard let milestoneDate = calendar.date(byAdding: .day, value: weekNum * 7, to: pregnancyStartDate) else {
                    continue
                }

                let dayKey = LocalDay.key(for: milestoneDate)
                let isPast = milestoneDate < now

                // Determine appointment / test status
                let appointmentDetails: AppointmentDetails?
                let medicalRecordDetails: MedicalRecordDetails?

                if milestone.category == .appointment {
                    appointmentDetails = AppointmentDetails(
                        clinicianOrClinic: profile.clinicalCareStatus.title,
                        location: milestone.isHospitalVisit ? "Hospital / OB Clinic" : "Clinic",
                        questions: milestone.questionsForDoctor.joined(separator: "\n• "),
                        status: isPast ? .completed : .scheduled
                    )
                    medicalRecordDetails = nil
                } else if milestone.category == .test {
                    appointmentDetails = nil
                    medicalRecordDetails = MedicalRecordDetails(
                        reportStatus: isPast ? .reportReceived : .planned,
                        followUpDayKey: nil
                    )
                } else {
                    appointmentDetails = nil
                    medicalRecordDetails = nil
                }

                let notesText = """
                \(milestone.clinicalPurpose)

                Key Questions for Clinician:
                • \(milestone.questionsForDoctor.joined(separator: "\n• "))
                """

                let instanceID = milestone.recurrenceWeeks != nil ? "\(milestone.id)_w\(weekNum)" : milestone.id
                let deterministicID = UUID(uuidString: Self.deterministicUUIDString(for: instanceID)) ?? UUID()

                let entry = CalendarEntry(
                    id: deterministicID,
                    title: milestone.title,
                    category: milestone.category,
                    dayKey: dayKey,
                    timeMinutes: milestone.defaultTimeMinutes,
                    notes: notesText,
                    createdAt: now,
                    modifiedAt: now,
                    attachments: [],
                    medicationID: nil,
                    appointment: appointmentDetails,
                    medicalRecord: medicalRecordDetails,
                    symptom: nil,
                    food: nil,
                    journal: nil,
                    milestone: MilestoneDetails(isPersonal: false),
                    task: TaskDetails(completed: isPast)
                )

                entries.append(entry)
            }
        }

        return entries
    }

    private func generateNonPregnantEntries(for profile: OnboardingProfile) -> [CalendarEntry] {
        let calendar = LocalDay.calendar
        let now = Date()
        var entries: [CalendarEntry] = []

        if profile.stage == .postpartum {
            // 2-Week Newborn Check & 6-Week OB/GYN Exam
            let deliveryDate = profile.childbirthDate ?? now

            if let twoWeekDate = calendar.date(byAdding: .day, value: 14, to: deliveryDate) {
                entries.append(CalendarEntry(
                    id: UUID(uuidString: Self.deterministicUUIDString(for: "postpartum_week_02")) ?? UUID(),
                    title: "2-Week Pediatric & Maternal Healing Checkup",
                    category: .appointment,
                    dayKey: LocalDay.key(for: twoWeekDate),
                    timeMinutes: 600,
                    notes: "Assessment of newborn feeding, weight gain, umbilical cord healing, and maternal postpartum recovery.",
                    createdAt: now,
                    modifiedAt: now,
                    attachments: [],
                    appointment: AppointmentDetails(clinicianOrClinic: "Pediatrician & Maternity Clinic", location: "Clinic", questions: "How is feeding and latch? Are post-birth pains easing?", status: twoWeekDate < now ? .completed : .scheduled)
                ))
            }

            if let sixWeekDate = calendar.date(byAdding: .day, value: 42, to: deliveryDate) {
                entries.append(CalendarEntry(
                    id: UUID(uuidString: Self.deterministicUUIDString(for: "postpartum_week_06")) ?? UUID(),
                    title: "6-Week Comprehensive Postpartum OB/GYN Exam",
                    category: .appointment,
                    dayKey: LocalDay.key(for: sixWeekDate),
                    timeMinutes: 630,
                    notes: "Comprehensive maternal postpartum evaluation: uterine involution, pelvic floor recovery, Edinburgh Postnatal Depression Scale (EPDS) wellbeing screening, and birth control consultation.",
                    createdAt: now,
                    modifiedAt: now,
                    attachments: [],
                    appointment: AppointmentDetails(clinicianOrClinic: "OB/GYN Clinic", location: "Clinic", questions: "How is pelvic floor recovery? Guidance on safe return to exercise.", status: sixWeekDate < now ? .completed : .scheduled)
                ))
            }
        }

        return entries
    }

    // MARK: - Store Synchronization

    /// Syncs the clinical schedule into `JournalStore`.
    /// Existing user entries (custom notes, food, symptoms, and completed visits) are strictly preserved.
    func syncSchedule(
        into store: JournalStore,
        profile: OnboardingProfile,
        forceRegenerate: Bool = false
    ) {
        let generatedEntries = generateEntries(for: profile)
        guard !generatedEntries.isEmpty else { return }

        // Find existing entries to preserve any user edits or completed statuses
        let existingEntriesByID = store.entriesByID

        for generated in generatedEntries {
            if let existing = existingEntriesByID[generated.id] {
                // If user already marked it completed or added attachments, don't overwrite their work
                if existing.appointment?.status == .completed ||
                   existing.medicalRecord?.reportStatus == .testCompleted ||
                   existing.medicalRecord?.reportStatus == .reportReceived ||
                   !existing.attachments.isEmpty {
                    continue
                }

                // If forceRegenerate is true, update the dayKey
                if forceRegenerate {
                    var updated = existing
                    updated.dayKey = generated.dayKey
                    updated.title = generated.title
                    updated.notes = generated.notes
                    store.upsertEntry(updated)
                }
            } else {
                // New milestone entry: insert it!
                store.upsertEntry(generated)
            }
        }
    }

    // MARK: - Missed Appointment & Test Detection

    struct MissedMilestoneReport: Identifiable, Equatable {
        let id: UUID
        let entry: CalendarEntry
        let milestone: MaternalClinicalMilestone?
        let originalDate: Date
        let daysOverdue: Int
        let suggestedRevisedDate: Date
        let isWithinAllowableWindow: Bool
    }

    func detectMissedEntries(in store: JournalStore) -> [MissedMilestoneReport] {
        let todayKey = LocalDay.key(for: Date())
        let todayDate = LocalDay.startOfDay(for: Date())
        let calendar = LocalDay.calendar

        var reports: [MissedMilestoneReport] = []

        for entry in store.entries {
            // Must be before today
            guard entry.dayKey < todayKey else { continue }

            // Check if it represents an uncompleted appointment or test
            let isAppointmentPending = entry.category == .appointment &&
                (entry.appointment?.status == .planned || entry.appointment?.status == .scheduled)

            let isTestPending = entry.category == .test &&
                (entry.medicalRecord?.reportStatus == .planned || entry.medicalRecord?.reportStatus == .followUpNeeded)

            guard isAppointmentPending || isTestPending else { continue }

            guard let entryDate = LocalDay.date(from: entry.dayKey) else { continue }
            let daysOverdue = max(1, calendar.dateComponents([.day], from: entryDate, to: todayDate).day ?? 1)

            // Look up matching milestone metadata if available
            let milestone = Self.allMilestones.first { entry.title.contains($0.title) || $0.title.contains(entry.title) }

            // Suggest rescheduling to the nearest upcoming weekday (today + 1 or 2 days)
            let suggestedDate = calendar.date(byAdding: .day, value: min(3, max(1, daysOverdue % 3 + 1)), to: todayDate) ?? todayDate

            // Check if still within safe clinical window (e.g., NT scan up to 13w6d)
            var withinWindow = true
            if milestone != nil {
                // Approximate: if overdue by more than 14 days, window might be tight
                withinWindow = daysOverdue <= 18
            }

            reports.append(MissedMilestoneReport(
                id: entry.id,
                entry: entry,
                milestone: milestone,
                originalDate: entryDate,
                daysOverdue: daysOverdue,
                suggestedRevisedDate: suggestedDate,
                isWithinAllowableWindow: withinWindow
            ))
        }

        return reports.sorted { $0.daysOverdue > $1.daysOverdue }
    }

    // MARK: - Smart Schedule Revision Engine

    /// Automatically reschedules a single missed appointment to a revised date
    @discardableResult
    func smartReviseMissedEntry(
        _ entry: CalendarEntry,
        in store: JournalStore,
        toTargetDate targetDate: Date? = nil
    ) -> Bool {
        var updated = entry
        let calendar = LocalDay.calendar
        let newDate = targetDate ?? calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let newDayKey = LocalDay.key(for: newDate)

        let originalDayText = LocalDay.dateText(for: entry.dayKey, style: .abbreviated)
        updated.dayKey = newDayKey
        updated.modifiedAt = Date()

        if var appt = updated.appointment {
            appt.status = .rescheduled
            updated.appointment = appt
        }

        updated.notes += "\n\n[Rescheduled by MamAmie Care Planner from \(originalDayText) to ensure continuous maternal care]."

        return store.upsertEntry(updated)
    }

    /// Automatically revises all missed appointments forward into the upcoming week in batch
    func smartReviseAllMissedEntries(in store: JournalStore) -> Int {
        let missed = detectMissedEntries(in: store)
        var revisedCount = 0

        for (index, report) in missed.enumerated() {
            // Stagger appointments across upcoming days so they don't all collide on one day
            let calendar = LocalDay.calendar
            let offsetDays = (index % 4) + 1
            let staggeredDate = calendar.date(byAdding: .day, value: offsetDays, to: Date()) ?? Date()

            if smartReviseMissedEntry(report.entry, in: store, toTargetDate: staggeredDate) {
                revisedCount += 1
            }
        }

        return revisedCount
    }

    // MARK: - Helper UUID Generator

    private static func deterministicUUIDString(for key: String) -> String {
        // Generates consistent deterministic UUID strings based on milestone keys
        let hash = abs(key.hashValue)
        let hexPart = String(format: "%08X", hash)
        return "B0000000-0000-0000-0000-0000\(hexPart)"
    }
}
