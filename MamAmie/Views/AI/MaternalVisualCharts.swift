import SwiftUI
import Charts

// MARK: - Trimester Cardiovascular Adaptation Chart
public struct MaternalHeartRateAdaptationChart: View {
    public struct AdaptationPoint: Identifiable {
        public let id = UUID()
        public let week: Int
        public let expectedBpm: Double
        public let lowerRange: Double
        public let upperRange: Double
        public let label: String
    }

    private let adaptationData: [AdaptationPoint] = [
        AdaptationPoint(week: 4, expectedBpm: 66, lowerRange: 60, upperRange: 74, label: "W4"),
        AdaptationPoint(week: 10, expectedBpm: 71, lowerRange: 64, upperRange: 78, label: "W10"),
        AdaptationPoint(week: 16, expectedBpm: 75, lowerRange: 68, upperRange: 82, label: "W16"),
        AdaptationPoint(week: 22, expectedBpm: 78, lowerRange: 70, upperRange: 85, label: "W22"),
        AdaptationPoint(week: 28, expectedBpm: 81, lowerRange: 73, upperRange: 88, label: "W28"),
        AdaptationPoint(week: 34, expectedBpm: 83, lowerRange: 75, upperRange: 90, label: "W34"),
        AdaptationPoint(week: 40, expectedBpm: 80, lowerRange: 72, upperRange: 88, label: "W40")
    ]

    public var currentWeek: Int = 18
    public var userRestingBpm: Double? = 74

    public init(currentWeek: Int = 18, userRestingBpm: Double? = 74) {
        self.currentWeek = currentWeek
        self.userRestingBpm = userRestingBpm
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Maternal Heart Rate Trajectory", systemImage: "waveform.path.ecg")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.42))

                Spacer()

                Text("ACOG / FOGSI Reference")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Chart {
                // Expected clinical range band
                ForEach(adaptationData) { pt in
                    AreaMark(
                        x: .value("Week", pt.week),
                        yStart: .value("Min", pt.lowerRange),
                        yEnd: .value("Max", pt.upperRange)
                    )
                    .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.42).opacity(0.12))

                    LineMark(
                        x: .value("Week", pt.week),
                        y: .value("Expected Avg", pt.expectedBpm)
                    )
                    .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.42))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                }

                // Current user marker if available
                if let bpm = userRestingBpm {
                    PointMark(
                        x: .value("Week", currentWeek),
                        y: .value("Your Rate", bpm)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text("You: \(Int(bpm)) bpm")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(radius: 2)
                    }
                }
            }
            .chartYScale(domain: 55...95)
            .chartXScale(domain: 2...42)
            .chartYAxis {
                AxisMarks(position: .leading, values: [60, 70, 80, 90]) { val in
                    AxisValueLabel {
                        if let v = val.as(Int.self) {
                            Text("\(v)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [4, 12, 20, 28, 36]) { val in
                    AxisValueLabel {
                        if let v = val.as(Int.self) {
                            Text("W\(v)")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.90, green: 0.28, blue: 0.42))
                        .frame(width: 8, height: 8)
                    Text("Expected +10-15 bpm rise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Your Smartwatch")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Maternal Micronutrient Requirements Comparison Chart
public struct MaternalNutrientComparisonChart: View {
    public struct NutrientBenchmark: Identifiable {
        public let id = UUID()
        public let name: String
        public let standard: Double
        public let pregnancy: Double
        public let unit: String
        public let percentageIncrease: Int
    }

    private let benchmarks: [NutrientBenchmark] = [
        NutrientBenchmark(name: "Folate", standard: 200, pregnancy: 400, unit: "mcg", percentageIncrease: 100),
        NutrientBenchmark(name: "Iron", standard: 18, pregnancy: 27, unit: "mg", percentageIncrease: 50),
        NutrientBenchmark(name: "Calcium", standard: 800, pregnancy: 1000, unit: "mg", percentageIncrease: 25),
        NutrientBenchmark(name: "Protein", standard: 46, pregnancy: 71, unit: "g", percentageIncrease: 54)
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Nutritional Demands: Standard vs Pregnancy", systemImage: "chart.bar.xaxis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))

                Spacer()

                Text("WHO / ICMR")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(benchmarks) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text("+\(item.percentageIncrease)% during pregnancy")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("AccentColor").opacity(0.12))
                                .clipShape(Capsule())
                        }

                        // Progress comparison bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background
                                Capsule()
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(height: 14)

                                // Standard need
                                let standardRatio = item.standard / item.pregnancy
                                Capsule()
                                    .fill(Color.secondary.opacity(0.4))
                                    .frame(width: max(20, geo.size.width * standardRatio), height: 14)

                                // Pregnancy goal
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("AccentColor").opacity(0.8), Color("AccentColor")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width, height: 14)
                                    .opacity(0.85)
                            }
                        }
                        .frame(height: 14)

                        HStack {
                            Text("Standard: \(Int(item.standard)) \(item.unit)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("Pregnancy Goal: \(Int(item.pregnancy)) \(item.unit)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                        }
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Maternal Sleep Architecture Breakdown
public struct MaternalSleepPositionChart: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sleep Position & Placental Perfusion", systemImage: "bed.double.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.78))

                Spacer()

                Text("RCOG Clinical Opinion")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                positionCard(
                    title: "Left Side",
                    quality: "Recommended",
                    score: "100%",
                    color: Color(red: 0.24, green: 0.72, blue: 0.58),
                    desc: "Maximizes IVC blood flow and kidney filtration"
                )

                positionCard(
                    title: "Right Side",
                    quality: "Acceptable",
                    score: "85%",
                    color: Color(red: 0.95, green: 0.65, blue: 0.25),
                    desc: "Safe alternative when left side gets tiring"
                )

                positionCard(
                    title: "Supine / Back",
                    quality: "Avoid T2/T3",
                    score: "40%",
                    color: Color(red: 0.90, green: 0.28, blue: 0.42),
                    desc: "Uterine weight can compress vena cava"
                )
            }

            Text("Tip: Place a pillow between your knees and under your belly to relieve lower back and pelvic pressure.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func positionCard(title: String, quality: String, score: String, color: Color, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())

            Text(quality)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.18))
                .foregroundStyle(color)
                .clipShape(Capsule())

            Text(desc)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Safe Heart Rate Zone Gauge
public struct MaternalActivityZoneChart: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Physical Activity Heart Rate Guide", systemImage: "figure.walk")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.24, green: 0.72, blue: 0.58))

                Spacer()

                Text("ACOG Guidelines")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                zoneRow(
                    range: "60 - 85 bpm",
                    label: "Rest & Recovery",
                    detail: "Sitting, reading, sleeping",
                    color: .blue
                )
                zoneRow(
                    range: "85 - 110 bpm",
                    label: "Gentle Movement",
                    detail: "Casual strolling, light stretching",
                    color: .teal
                )
                zoneRow(
                    range: "110 - 140 bpm",
                    label: "Target Exercise Zone",
                    detail: "Brisk walking, prenatal yoga, swimming",
                    color: Color(red: 0.24, green: 0.72, blue: 0.58)
                )
                zoneRow(
                    range: "> 145 bpm",
                    label: "High Exertion",
                    detail: "Slow down, hydrate, and take a break",
                    color: Color(red: 0.90, green: 0.28, blue: 0.42)
                )
            }

            Text("You should always be able to maintain a conversation while walking or exercising ('The Talk Test').")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func zoneRow(range: String, label: String, detail: String, color: Color) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(range)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                }

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
