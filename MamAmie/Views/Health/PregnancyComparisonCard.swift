import SwiftUI

struct PregnancyComparisonCard: View {
    let metric: HealthMetricType
    let values: [Double]
    let profile: MaternalHealthProfile

    private var average: Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var reference: PregnancyReference {
        PregnancyReferenceLibrary.reference(for: metric)
    }

    private var isPregnancyReferenceApplicable: Bool {
        profile.stage != .planning && profile.stage != .postpartum
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 34, height: 34)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pregnancy context")
                        .font(.headline)
                    Text("Compared with a broad reference for pregnant adults")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !isPregnancyReferenceApplicable {
                Text("A pregnancy reference is not shown for the current \(profile.stage.rawValue.lowercased()) stage. Your personal trend remains available above.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let average {
                comparisonContent(userAverage: average)
            } else {
                Text("Add more recorded readings to compare your period average with this reference.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("This comparison is for personal context only. It is not a medical target, diagnosis, or substitute for your care team.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AccentColor").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func comparisonContent(userAverage: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Your period average")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(userAverage))
                    .font(.title3.bold())
                Text(reference.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                comparisonValue(
                    title: "Reference average",
                    value: reference.average
                )
                comparisonValue(
                    title: "Reference range",
                    value: nil,
                    range: reference.range
                )
            }

            HStack(spacing: 8) {
                Image(systemName: relationIcon(for: userAverage))
                    .foregroundStyle(relationColor(for: userAverage))
                Text(reference.relation(for: userAverage).title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(relationColor(for: userAverage))
            }

            Text(reference.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(reference.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func comparisonValue(
        title: String,
        value: Double?,
        range: ClosedRange<Double>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let value {
                Text(format(value))
                    .font(.subheadline.weight(.bold))
            } else if let range {
                Text("\(format(range.lowerBound))–\(format(range.upperBound))")
                    .font(.subheadline.weight(.bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func format(_ value: Double) -> String {
        switch metric {
        case .bloodOxygen:
            return String(format: "%.0f%%", value)
        case .sleep:
            return String(format: "%.1f", value)
        case .activity:
            return NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal)
        case .wristTemperature:
            return String(format: "%.1f", value)
        default:
            return String(format: "%.0f", value)
        }
    }

    private func relationIcon(for value: Double) -> String {
        switch reference.relation(for: value) {
        case .below: return "arrow.down.right"
        case .within: return "checkmark.circle.fill"
        case .above: return "arrow.up.right"
        }
    }

    private func relationColor(for value: Double) -> Color {
        switch reference.relation(for: value) {
        case .below, .above: return .orange
        case .within: return Color("AccentColor")
        }
    }
}
