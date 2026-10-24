import SwiftUI

struct DayWeightTrackerView: View {
    @ObservedObject var store: JournalStore
    let dayKey: String

    @AppStorage("mamamie_weight_unit") private var weightUnit: String = "kg"
    @AppStorage("mamamie_baseline_weight") private var baselineWeight: Double = 60.0
    @State private var inputWeightText: String = ""
    @State private var showingEditSheet: Bool = false

    private var existingWeightEntry: CalendarEntry? {
        store.entries(for: dayKey).first { $0.weight != nil }
    }

    private var currentWeight: Double? {
        existingWeightEntry?.weight?.weightKg
    }

    private var weightChangeFromBaseline: Double? {
        guard let current = currentWeight else { return nil }
        return current - baselineWeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "scalemass.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)

                    Text("Weight Tracking")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                if let current = currentWeight {
                    HStack(spacing: 4) {
                        Text(formatWeight(current))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.purple)

                        Button {
                            inputWeightText = String(format: "%.1f", displayValue(current))
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Button {
                        inputWeightText = String(format: "%.1f", displayValue(baselineWeight))
                        showingEditSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Weight")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            // Weight Status & Gestational Reference
            if let current = currentWeight {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recorded Today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatWeight(current))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    Divider().frame(height: 28)

                    if let diff = weightChangeFromBaseline {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Overall Change")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(diff >= 0 ? "+" : "")\(formatWeightDiff(diff))")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(diff >= 0 ? .green : .orange)
                        }

                        Divider().frame(height: 28)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACOG Rate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("~0.4 kg/wk")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            } else {
                Text("Log your weight today to keep track of steady, healthy gestational weight gain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Log Your Weight")
                        .font(.headline)
                        .padding(.top, 16)

                    // Unit Picker
                    Picker("Unit", selection: $weightUnit) {
                        Text("Kilograms (kg)").tag("kg")
                        Text("Pounds (lbs)").tag("lbs")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Numeric display
                    VStack(spacing: 8) {
                        TextField("Weight", text: $inputWeightText)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)

                        Text(weightUnit.uppercased())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Quick Step Buttons
                    HStack(spacing: 16) {
                        Button {
                            adjustWeight(by: -0.5)
                        } label: {
                            Text("- 0.5")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }

                        Button {
                            adjustWeight(by: +0.5)
                        } label: {
                            Text("+ 0.5")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }

                    Spacer()

                    Button {
                        saveWeight()
                        showingEditSheet = false
                    } label: {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .navigationTitle("Maternal Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEditSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func displayValue(_ kg: Double) -> Double {
        if weightUnit == "lbs" {
            return kg * 2.20462
        }
        return kg
    }

    private func formatWeight(_ kg: Double) -> String {
        if weightUnit == "lbs" {
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
        return String(format: "%.1f kg", kg)
    }

    private func formatWeightDiff(_ kg: Double) -> String {
        if weightUnit == "lbs" {
            let lbs = kg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
        return String(format: "%.1f kg", kg)
    }

    private func adjustWeight(by delta: Double) {
        let current = Double(inputWeightText.replacingOccurrences(of: ",", with: ".")) ?? displayValue(baselineWeight)
        let updated = max(30.0, current + delta)
        inputWeightText = String(format: "%.1f", updated)
    }

    private func saveWeight() {
        guard let entered = Double(inputWeightText.replacingOccurrences(of: ",", with: ".")) else { return }
        let kgValue = (weightUnit == "lbs") ? (entered / 2.20462) : entered

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let now = Date()

        if var existing = existingWeightEntry {
            existing.weight = WeightDetails(weightKg: kgValue, unit: weightUnit)
            existing.title = "Maternal Weight: \(formatWeight(kgValue))"
            existing.modifiedAt = now
            store.upsertEntry(existing)
        } else {
            let newEntry = CalendarEntry(
                id: UUID(),
                title: "Maternal Weight: \(formatWeight(kgValue))",
                category: .symptom,
                dayKey: dayKey,
                timeMinutes: LocalDay.minutes(for: now),
                notes: "Recorded maternal weight for \(LocalDay.dateText(for: dayKey, style: .abbreviated)).",
                createdAt: now,
                modifiedAt: now,
                attachments: [],
                weight: WeightDetails(weightKg: kgValue, unit: weightUnit)
            )
            store.upsertEntry(newEntry)
        }
    }
}
