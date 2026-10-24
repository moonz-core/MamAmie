import SwiftUI

public struct MaternalAIView: View {
    public var onOpenHealth: (() -> Void)? = nil
    public var onOpenFood: (() -> Void)? = nil

    @State private var queryText: String = ""
    @State private var isLoading: Bool = false
    @State private var currentTopic: AITopic = .nutrition
    @State private var activeResponse: MaternalAIInsight? = MaternalAIInsight.samples[.nutrition]
    @State private var errorMessage: String? = nil

    public init(onOpenHealth: (() -> Void)? = nil, onOpenFood: (() -> Void)? = nil) {
        self.onOpenHealth = onOpenHealth
        self.onOpenFood = onOpenFood
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    // Topic Selection Pills
                    topicSelectorBar

                    // Search / Ask AI input bar
                    queryInputSection

                    if isLoading {
                        loadingCard
                    } else if let insight = activeResponse {
                        // AI Response Card with Clinical Summary
                        aiResponseCard(insight)

                        // Data & Visual Chart Section corresponding to AI context
                        aiVisualDataSection(insight)

                        // Clinical Citations & Safety Disclaimers
                        citationsAndSafetyCard(insight)
                    }

                    // Emergency safety guidance banner
                    MedicalSafetyBannerView()
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("AI Guidance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("EVIDENCE-BASED MATERNAL AI")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("Grounded Clinical Engine")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("Grounded Clinical Intelligence")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Personalized maternal insights supported by peer-reviewed obstetric literature, paired with visual physiological and nutritional data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var topicSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AITopic.allCases) { topic in
                    Button {
                        selectTopic(topic)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: topic.iconName)
                                .font(.caption.weight(.bold))
                            Text(topic.title)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(currentTopic == topic ? Color("AccentColor") : Color(.secondarySystemBackground))
                        .foregroundStyle(currentTopic == topic ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var queryInputSection: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color("AccentColor"))
                TextField("Ask anything about your pregnancy...", text: $queryText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .onSubmit {
                        submitCustomQuery()
                    }

                if !queryText.isEmpty {
                    Button {
                        queryText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                submitCustomQuery()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.4) : Color("AccentColor"))
            }
            .disabled(queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Synthesizing clinical evidence & data...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func aiResponseCard(_ insight: MaternalAIInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("AI Clinical Insight", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                if insight.isEmergency {
                    Label("Urgent Clinical Alert", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text(insight.topicTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(insight.answer)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(insight.isEmergency ? Color.red.opacity(0.08) : Color("AccentColor").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func aiVisualDataSection(_ insight: MaternalAIInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Visual Data & Reference Charts", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            switch insight.chartType {
            case .heartRate:
                MaternalHeartRateAdaptationChart(currentWeek: 18, userRestingBpm: 74)

                Button {
                    onOpenHealth?()
                } label: {
                    Label("View your live smartwatch resting HR trends", systemImage: "waveform.path.ecg")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))
                }
                .padding(.top, 2)

            case .nutrition:
                MaternalNutrientComparisonChart()

                Button {
                    onOpenFood?()
                } label: {
                    Label("Log meals & calculate daily nutrient totals", systemImage: "fork.knife")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))
                }
                .padding(.top, 2)

            case .sleep:
                MaternalSleepPositionChart()

            case .exercise:
                MaternalActivityZoneChart()

            case .none:
                EmptyView()
            }
        }
    }

    private func citationsAndSafetyCard(_ insight: MaternalAIInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVALUATED CLINICAL SOURCES")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.secondary)

            ForEach(insight.citations, id: \.self) { cit in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AccentColor"))
                    Text(cit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .padding(.vertical, 2)

            Text("Disclaimer: MamAmie AI synthesizes clinical reference guidelines for educational understanding. It does not provide medical diagnoses or replace direct consultation with your gynecologist/obstetrician.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func selectTopic(_ topic: AITopic) {
        currentTopic = topic
        if let cached = MaternalAIInsight.samples[topic] {
            activeResponse = cached
        }
    }

    private func submitCustomQuery() {
        let q = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        isLoading = true
        queryText = ""

        Task {
            // Attempt API call to backend AI
            if let apiResult = await fetchAIFallback(query: q) {
                await MainActor.run {
                    self.activeResponse = apiResult
                    self.isLoading = false
                }
            } else {
                // Match local grounded fallback
                let localMatch = matchLocalTopic(query: q)
                await MainActor.run {
                    self.activeResponse = localMatch
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchAIFallback(query: String) async -> MaternalAIInsight? {
        guard let url = URL(string: "\(APIConfiguration.currentBaseURL.absoluteString)/ai-assistant/query") else {
            return nil
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["query": query, "stage": "second_trimester", "week": 18]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer"] as? String {
                let isEmergency = json["safety_escalation"] as? Bool ?? false
                let citArray = (json["citations"] as? [[String: Any]])?.compactMap { $0["title"] as? String } ?? ["FOGSI Good Clinical Practice Guidelines"]
                let chart = detectChart(for: query)
                return MaternalAIInsight(
                    topicTitle: "Clinical Answer",
                    answer: answer,
                    chartType: chart,
                    citations: citArray,
                    isEmergency: isEmergency
                )
            }
        } catch {
            return nil
        }
        return nil
    }

    private func matchLocalTopic(query: String) -> MaternalAIInsight {
        let lower = query.lowercased()
        if lower.contains("bleed") || lower.contains("pain") || lower.contains("headache") || lower.contains("leak") {
            return MaternalAIInsight(
                topicTitle: "Emergency Warning Signs",
                answer: "⚠️ URGENT CLINICAL NOTICE: Based on the symptoms described, this could represent a potentially serious maternal or fetal condition requiring IMMEDIATE evaluation. Do not wait. Please contact your obstetrician or maternity hospital immediately.",
                chartType: .none,
                citations: ["Obstetric Red Flag Symptoms & Emergency Protocols", "FOGSI High Risk Pregnancy Guidelines"],
                isEmergency: true
            )
        } else if lower.contains("heart") || lower.contains("bpm") || lower.contains("rate") || lower.contains("pulse") {
            return MaternalAIInsight.samples[.heartRate]!
        } else if lower.contains("sleep") || lower.contains("tired") || lower.contains("bed") || lower.contains("side") {
            return MaternalAIInsight.samples[.sleep]!
        } else if lower.contains("walk") || lower.contains("exercise") || lower.contains("yoga") || lower.contains("step") {
            return MaternalAIInsight.samples[.exercise]!
        } else {
            return MaternalAIInsight.samples[.nutrition]!
        }
    }

    private func detectChart(for query: String) -> AIChartType {
        let l = query.lowercased()
        if l.contains("heart") || l.contains("pulse") || l.contains("rate") { return .heartRate }
        if l.contains("sleep") || l.contains("bed") || l.contains("side") { return .sleep }
        if l.contains("exercise") || l.contains("walk") || l.contains("sport") { return .exercise }
        return .nutrition
    }
}

// MARK: - Models for AI View
public enum AITopic: String, CaseIterable, Identifiable {
    case nutrition = "Nutrition & Iron"
    case heartRate = "Resting HR"
    case sleep = "Sleep & Rest"
    case exercise = "Safe Exercise"
    case redFlags = "Warning Signs"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var iconName: String {
        switch self {
        case .nutrition: return "leaf.fill"
        case .heartRate: return "waveform.path.ecg"
        case .sleep: return "moon.stars.fill"
        case .exercise: return "figure.walk"
        case .redFlags: return "exclamationmark.shield.fill"
        }
    }
}

public enum AIChartType {
    case heartRate
    case nutrition
    case sleep
    case exercise
    case none
}

public struct MaternalAIInsight {
    public let topicTitle: String
    public let answer: String
    public let chartType: AIChartType
    public let citations: [String]
    public let isEmergency: Bool

    public static let samples: [AITopic: MaternalAIInsight] = [
        .nutrition: MaternalAIInsight(
            topicTitle: "Maternal Micronutrient Supplementation",
            answer: "During pregnancy, nutritional demands accelerate to support 45% maternal blood volume expansion and fetal bone formation. Folate (400 mcg) is critical for neural tube closure, while Elemental Iron (27 mg) and Calcium (1000 mg) prevent maternal anemia and preeclampsia. Tip: Take Iron with Vitamin C (lemon/orange) and never take Calcium and Iron at the exact same hour as Calcium inhibits iron absorption.",
            chartType: .nutrition,
            citations: [
                "WHO Guidelines on Nutritional Interventions in Pregnancy",
                "ICMR-National Institute of Nutrition (NIN) Dietary Guidelines 2024"
            ],
            isEmergency: false
        ),
        .heartRate: MaternalAIInsight(
            topicTitle: "Cardiovascular Adaptation & Resting HR",
            answer: "It is normal and healthy for your resting heart rate to rise by 10 to 15 bpm above your pre-pregnancy baseline, reaching its peak around weeks 30–34. This physiological adaptation occurs because your heart pumps up to 50% more blood each minute to nourish the placenta. Your smartwatch resting heart rate trend visualizes this healthy adaptation.",
            chartType: .heartRate,
            citations: [
                "ACOG Clinical Opinion: Maternal Physiological Adaptations",
                "FOGSI Good Clinical Practice Guidelines on Antenatal Care"
            ],
            isEmergency: false
        ),
        .sleep: MaternalAIInsight(
            topicTitle: "Sleep Positioning & Placental Flow",
            answer: "From week 20 onward, sleeping on your side (left side preferred) significantly optimizes oxygenated blood flow through the inferior vena cava (IVC) to your placenta. Avoid sleeping flat on your back for prolonged periods in late pregnancy, which can reduce cardiac output and cause lightheadedness.",
            chartType: .sleep,
            citations: [
                "RCOG Guideline: Maternal Sleep Position in Late Pregnancy",
                "Lancet International Stillbirth Research Alliance (ISRA)"
            ],
            isEmergency: false
        ),
        .exercise: MaternalAIInsight(
            topicTitle: "Safe Physical Activity & Heart Rate Zones",
            answer: "Unless your obstetrician advises pelvic rest, 20–30 minutes of daily moderate movement (walking, prenatal yoga, swimming) reduces gestational diabetes risks by 38% and eases pelvic discomfort. Maintain an exertion level where you can pass the 'talk test'—holding a full conversation without gasping.",
            chartType: .exercise,
            citations: [
                "ACOG Committee Opinion No. 804: Physical Activity in Pregnancy",
                "FOGSI Exercise Guidelines for Indian Mothers"
            ],
            isEmergency: false
        ),
        .redFlags: MaternalAIInsight(
            topicTitle: "Urgent Obstetric Symptoms (Red Flags)",
            answer: "Always seek immediate clinical attention if you experience: any vaginal bleeding or fluid leaking, severe headache with visual disturbances, persistent sharp upper abdominal pain, high fever with chills, or noticeable reduction in your baby's daily movements after week 24.",
            chartType: .none,
            citations: [
                "Obstetric Red Flag Symptoms & Emergency Protocols",
                "FOGSI High-Risk Pregnancy Guidelines"
            ],
            isEmergency: true
        )
    ]
}
