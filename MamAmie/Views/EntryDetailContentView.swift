import SwiftUI

struct EntryDetailContentView: View {
    @ObservedObject var store: JournalStore
    let entry: CalendarEntry

    @ViewBuilder
    var body: some View {
        switch entry.category {
        case .medication:
            MedicationDetailsView(store: store, entry: entry)
        case .appointment:
            AppointmentDetailsView(entry: entry)
        case .test:
            MedicalRecordDetailsView(entry: entry)
        case .symptom:
            SymptomDetailsView(entry: entry)
        case .food:
            FoodDetailsView(entry: entry)
        case .journal:
            JournalDetailsView(entry: entry)
        case .milestone:
            MilestoneDetailsView(entry: entry)
        case .task:
            TaskDetailsView(entry: entry)
        case .photo:
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct MedicationDetailsView: View {
    @ObservedObject var store: JournalStore
    let entry: CalendarEntry

    private var logs: [MedicationDoseLog] {
        store.doseLogs(for: entry)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let schedule = store.medicationSchedule(for: entry) {
                DetailCardView {
                    DetailLineView(label: "Dose", value: schedule.dose.isEmpty ? "Not specified" : schedule.dose)
                    if !schedule.instructions.isEmpty {
                        DetailLineView(label: "Instructions", value: schedule.instructions)
                    }
                    if !schedule.recurrence.isEmpty {
                        DetailLineView(label: "Schedule", value: schedule.recurrence)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Log what happened")
                        .font(.headline)
                    Text("A reminder or schedule never marks a dose as taken. Record what you report here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(DoseStatus.allCases) { status in
                            Button(status.displayName) {
                                _ = store.logDose(for: entry, status: status)
                            }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.bordered)
                            .tint(status == .taken ? Color("AccentColor") : .secondary)
                        }
                    }

                    if !logs.isEmpty {
                        Text("Dose history")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)

                        ForEach(Array(logs.prefix(6))) { log in
                            HStack {
                                Text(LocalDay.dateText(for: log.dayKey))
                                Spacer()
                                Text(log.status.displayName)
                                    .foregroundStyle(log.status == .taken ? Color("AccentColor") : .secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding(16)
                .background(Color("AccentColor").opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            NotesCardView(notes: entry.notes)
        }
    }
}

private struct AppointmentDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let appointment = entry.appointment {
                DetailCardView {
                    DetailLineView(label: "Status", value: appointment.status.displayName)
                    if !appointment.clinicianOrClinic.isEmpty {
                        DetailLineView(label: "Doctor or clinic", value: appointment.clinicianOrClinic)
                    }
                    if !appointment.location.isEmpty {
                        DetailLineView(label: "Location", value: appointment.location)
                    }
                    if !appointment.questions.isEmpty {
                        DetailLineView(label: "Questions", value: appointment.questions)
                    }
                }
            }
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct MedicalRecordDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let record = entry.medicalRecord {
                DetailCardView {
                    DetailLineView(label: "Report status", value: record.reportStatus.displayName)
                    if let followUpDayKey = record.followUpDayKey {
                        DetailLineView(
                            label: "Follow-up",
                            value: LocalDay.dateText(for: followUpDayKey, style: .long)
                        )
                    }
                }
            }
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct SymptomDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let symptom = entry.symptom {
                DetailCardView {
                    DetailLineView(label: "Severity", value: symptom.severity.displayName)
                    if !symptom.duration.isEmpty {
                        DetailLineView(label: "Duration", value: symptom.duration)
                    }
                    if symptom.discussWithClinician {
                        Label(
                            "Marked to discuss with a healthcare professional",
                            systemImage: "checkmark.circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color("AccentColor"))
                    }
                }
            }
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct FoodDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let food = entry.food {
                DetailCardView {
                    DetailLineView(label: "Meal", value: food.meal.displayName)
                    if !food.ingredients.isEmpty {
                        DetailLineView(label: "Ingredients", value: food.ingredients)
                    }
                    if !food.portion.isEmpty {
                        DetailLineView(label: "Portion", value: food.portion)
                    }
                }

                // Nutrition Breakdown Card
                if food.calories != nil || food.proteinG != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color("AccentColor"))
                            Text("Nutritional Breakdown")
                                .font(.subheadline.weight(.semibold))
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            if let cal = food.calories {
                                nutrientPill(label: "Calories", value: "\(Int(cal)) kcal", color: .orange)
                            }
                            if let p = food.proteinG {
                                nutrientPill(label: "Protein", value: "\(String(format: "%.1f", p)) g", color: .blue)
                            }
                            if let c = food.carbsG {
                                nutrientPill(label: "Carbohydrates", value: "\(String(format: "%.1f", c)) g", color: .purple)
                            }
                            if let f = food.fatG {
                                nutrientPill(label: "Fats", value: "\(String(format: "%.1f", f)) g", color: .mint)
                            }
                            if let iron = food.ironMg {
                                nutrientPill(label: "Iron", value: "\(String(format: "%.1f", iron)) mg", color: .red)
                            }
                            if let fol = food.folateMcg {
                                nutrientPill(label: "Folate", value: "\(Int(fol)) mcg", color: .green)
                            }
                            if let calc = food.calciumMg {
                                nutrientPill(label: "Calcium", value: "\(Int(calc)) mg", color: .indigo)
                            }
                            if let d = food.vitaminDMcg {
                                nutrientPill(label: "Vitamin D", value: "\(String(format: "%.1f", d)) mcg", color: .yellow)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // AI Recommended Supplements & Foods
                if !food.suggestedSupplements.isEmpty || !food.suggestedFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "pill.fill")
                                .foregroundStyle(.purple)
                            Text("AI Recommended Supplements & Foods")
                                .font(.subheadline.weight(.semibold))
                        }

                        if !food.suggestedSupplements.isEmpty {
                            Text("Supplements to Buy:")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            ForEach(food.suggestedSupplements, id: \.self) { supp in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundStyle(.purple)
                                    Text(supp)
                                        .font(.caption)
                                }
                            }
                        }

                        if !food.suggestedFoods.isEmpty {
                            Text("Recommended Next Meals/Snacks:")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            ForEach(food.suggestedFoods, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundStyle(.green)
                                    Text(item)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            NotesCardView(notes: entry.notes)
        }
    }

    private func nutrientPill(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct JournalDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let mood = entry.journal?.mood, !mood.isEmpty {
                Text("Feeling: \(mood)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("AccentColor"))
            }
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct MilestoneDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entry.milestone?.isPersonal == true {
                Label("Personal milestone", systemImage: "heart.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("AccentColor"))
            }
            NotesCardView(notes: entry.notes)
        }
    }
}

private struct TaskDetailsView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entry.task?.completed == true {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color("AccentColor"))
            } else {
                Label("To do", systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
            NotesCardView(notes: entry.notes)
        }
    }
}
