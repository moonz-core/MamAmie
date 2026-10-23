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
            }
            NotesCardView(notes: entry.notes)
        }
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
