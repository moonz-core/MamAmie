import SwiftUI

struct ClinicalCarePlanView: View {
    @ObservedObject var store: JournalStore
    @ObservedObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTrimester: Int = 1
    @State private var showingRegenerateConfirmation = false
    @State private var editingEntry: CalendarEntry?
    @State private var revisedDate = Date()
    @State private var showingDatePicker = false

    private var profile: OnboardingProfile? {
        onboardingStore.profile
    }

    private var currentWeek: Int {
        profile?.gestationalWeek ?? 12
    }

    private var currentTrimester: Int {
        if currentWeek <= 13 { return 1 }
        if currentWeek <= 27 { return 2 }
        return 3
    }

    private var missedReports: [MaternalSchedulePlanner.MissedMilestoneReport] {
        MaternalSchedulePlanner.shared.detectMissedEntries(in: store)
    }

    private var allClinicalEntries: [CalendarEntry] {
        store.entries
            .filter { $0.category == .appointment || $0.category == .test }
            .sorted { $0.dayKey < $1.dayKey }
    }

    private var completedCount: Int {
        allClinicalEntries.filter {
            $0.appointment?.status == .completed ||
            $0.medicalRecord?.reportStatus == .testCompleted ||
            $0.medicalRecord?.reportStatus == .reportReceived
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Overview Card
                    overviewCard

                    // Missed Appointments Warning & Auto-Revision Banner
                    if !missedReports.isEmpty {
                        missedAppointmentsBanner
                    }

                    // Trimester Picker
                    trimesterPicker

                    // Milestones List for Selected Trimester
                    milestonesList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Clinical Care Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingRegenerateConfirmation = true
                        } label: {
                            Label("Re-sync from Due Date", systemImage: "arrow.triangle.2.circlepath")
                        }

                        if !missedReports.isEmpty {
                            Button {
                                _ = MaternalSchedulePlanner.shared.smartReviseAllMissedEntries(in: store)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            } label: {
                                Label("Auto-Revise Missed Dates", systemImage: "clock.arrow.circlepath")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                selectedTrimester = currentTrimester
            }
            .alert("Re-sync Clinical Schedule?", isPresented: $showingRegenerateConfirmation) {
                Button("Re-sync", role: .destructive) {
                    if let prof = profile {
                        MaternalSchedulePlanner.shared.syncSchedule(into: store, profile: prof, forceRegenerate: true)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will recalculate all pending sonography scans, lab tests, and doctor checkup dates based on your pregnancy due date.")
            }
            .sheet(item: $editingEntry) { entry in
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Reschedule Appointment")
                            .font(.headline)
                            .padding(.top, 16)

                        Text(entry.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        DatePicker("New Date", selection: $revisedDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding()

                        Button {
                            MaternalSchedulePlanner.shared.smartReviseMissedEntry(entry, in: store, toTargetDate: revisedDate)
                            editingEntry = nil
                        } label: {
                            Text("Confirm New Date")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { editingEntry = nil }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.stage == .pregnant ? "Week \(currentWeek) • Trimester \(currentTrimester)" : "Your Care Roadmap")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))

                    if let due = profile?.estimatedDueDate {
                        Text("Estimated Due Date: \(due.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                    .padding(10)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Clinical Milestones Completed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(completedCount) of \(allClinicalEntries.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        let progress = allClinicalEntries.isEmpty ? 0.0 : Double(completedCount) / Double(allClinicalEntries.count)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color("AccentColor"), Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * CGFloat(progress)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Missed Appointments Banner

    private var missedAppointmentsBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(missedReports.count) Missed or Pending Milestone\(missedReports.count > 1 ? "s" : "")")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Important tests or checkups scheduled in the past were not marked complete.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Quick Auto-Revise Button
            HStack(spacing: 12) {
                Button {
                    _ = MaternalSchedulePlanner.shared.smartReviseAllMissedEntries(in: store)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Auto-Revise to Upcoming Days")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }

            // List of specific missed items
            VStack(spacing: 8) {
                ForEach(missedReports.prefix(3)) { report in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.entry.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Text("Was on \(LocalDay.dateText(for: report.entry.dayKey)) • \(report.daysOverdue)d overdue")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }

                        Spacer()

                        Button("Done") {
                            var updated = report.entry
                            if var appt = updated.appointment {
                                appt.status = .completed
                                updated.appointment = appt
                            }
                            if var med = updated.medicalRecord {
                                med.reportStatus = .testCompleted
                                updated.medicalRecord = med
                            }
                            store.upsertEntry(updated)
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .tint(.green)

                        Button("Reschedule") {
                            editingEntry = report.entry
                            revisedDate = report.suggestedRevisedDate
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Trimester Picker

    private var trimesterPicker: some View {
        Picker("Trimester", selection: $selectedTrimester) {
            Text("1st Trimester (1–13w)").tag(1)
            Text("2nd Trimester (14–27w)").tag(2)
            Text("3rd Trimester (28–40w)").tag(3)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Milestones List

    private var milestonesList: some View {
        let filteredMilestones = MaternalSchedulePlanner.allMilestones.filter { milestone in
            switch selectedTrimester {
            case 1: return milestone.weekNumber <= 13
            case 2: return milestone.weekNumber >= 14 && milestone.weekNumber <= 27
            case 3: return milestone.weekNumber >= 28
            default: return true
            }
        }

        return VStack(alignment: .leading, spacing: 14) {
            ForEach(filteredMilestones) { milestone in
                let matchingEntry = store.entries.first {
                    $0.title.contains(milestone.title) || milestone.title.contains($0.title)
                }
                MilestoneCareCard(
                    milestone: milestone,
                    entry: matchingEntry,
                    onMarkCompleted: { entry in
                        var updated = entry
                        if var appt = updated.appointment {
                            appt.status = .completed
                            updated.appointment = appt
                        }
                        if var med = updated.medicalRecord {
                            med.reportStatus = .testCompleted
                            updated.medicalRecord = med
                        }
                        store.upsertEntry(updated)
                    },
                    onReschedule: { entry in
                        editingEntry = entry
                        if let date = LocalDay.date(from: entry.dayKey) {
                            revisedDate = date
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Milestone Care Card Component

private struct MilestoneCareCard: View {
    let milestone: MaternalClinicalMilestone
    let entry: CalendarEntry?
    let onMarkCompleted: (CalendarEntry) -> Void
    let onReschedule: (CalendarEntry) -> Void

    @State private var isExpanded: Bool = false

    private var isCompleted: Bool {
        guard let entry else { return false }
        return entry.appointment?.status == .completed ||
               entry.medicalRecord?.reportStatus == .testCompleted ||
               entry.medicalRecord?.reportStatus == .reportReceived
    }

    private var isOverdue: Bool {
        guard let entry, !isCompleted else { return false }
        return entry.dayKey < LocalDay.key(for: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Category Icon Badge
                Image(systemName: milestone.isSonography ? "doc.text.magnifyingglass" : (milestone.category == .appointment ? "stethoscope" : "drop.fill"))
                    .font(.headline)
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Week \(milestone.weekNumber)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AccentColor"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("AccentColor").opacity(0.12))
                            .clipShape(Capsule())

                        if milestone.isSonography {
                            Text("Sonography")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        if milestone.isHospitalVisit {
                            Text("Hospital Visit")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        statusPill
                    }

                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let entry = entry {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(LocalDay.dateText(for: entry.dayKey, style: .medium))
                                .font(.caption)

                            if let minutes = entry.timeMinutes {
                                Text("• \(LocalDay.timeText(for: minutes))")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                }
            }

            // Clinical Purpose Details
            Text(milestone.clinicalPurpose)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 2)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Questions to Ask Your Doctor:")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)

                    ForEach(milestone.questionsForDoctor, id: \.self) { question in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AccentColor"))
                            Text(question)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }

            // Action bar
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Less details" : "More details")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color("AccentColor"))
                }

                Spacer()

                if let entry = entry {
                    if !isCompleted {
                        Button {
                            onMarkCompleted(entry)
                        } label: {
                            Label("Mark Done", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)

                        Button {
                            onReschedule(entry)
                        } label: {
                            Label("Reschedule", systemImage: "calendar.badge.clock")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(Color("AccentColor"))
                    } else {
                        Label("Completed", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private var iconColor: Color {
        if milestone.isSonography { return .purple }
        if milestone.category == .appointment { return Color("AccentColor") }
        return .red
    }

    private var statusPill: some View {
        Group {
            if isCompleted {
                Text("Completed")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            } else if isOverdue {
                Text("Action Needed")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("Planned")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }
}
