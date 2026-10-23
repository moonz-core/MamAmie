import SwiftUI

public struct MedicalSafetyBannerView: View {
    @State private var isExpanded: Bool = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.title3)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 32, height: 32)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Medical & Safety Reminder")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Smartwatch measurements are for maternal wellness tracking only. Wearable sensors do not monitor fetal heart rate or diagnose pregnancy conditions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.vertical, 2)

                    Text("When to seek immediate medical care:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 6) {
                        UrgentSignRow(text: "Severe, persistent headache or sudden vision changes")
                        UrgentSignRow(text: "Sudden swelling of face, hands, or feet")
                        UrgentSignRow(text: "Sharp abdominal pain or cramping")
                        UrgentSignRow(text: "Vaginal bleeding or fluid leakage")
                        UrgentSignRow(text: "Noticeable reduction in fetal movements (after 24 weeks)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("Never rely on wearable readings to evaluate an urgent symptom. Always contact your obstetrician, midwife, or local emergency services.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show less" : "Important symptoms to report")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color("AccentColor"))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct UrgentSignRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(Color("AccentColor"))
                .padding(.top, 5)

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
