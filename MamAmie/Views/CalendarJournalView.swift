import SwiftUI

struct CalendarJournalView: View {
    @ObservedObject var store: JournalStore
    @ObservedObject var onboardingStore: OnboardingStore

    @State private var selectedDate = Date()
    @State private var displayedMonth = LocalDay.startOfMonth(for: Date())
    @State private var showingAddEntry = false
    @State private var showingCarePlanSheet = false
    @State private var selectedEntry: CalendarEntrySelection?

    private var profile: OnboardingProfile? {
        onboardingStore.profile
    }

    private var currentWeek: Int {
        profile?.gestationalWeek ?? 12
    }

    private var selectedDayKey: String {
        LocalDay.key(for: selectedDate)
    }

    private var missedReports: [MaternalSchedulePlanner.MissedMilestoneReport] {
        MaternalSchedulePlanner.shared.detectMissedEntries(in: store)
    }

    private var nextClinicalMilestone: CalendarEntry? {
        let todayKey = LocalDay.key(for: Date())
        return store.entries
            .filter { ($0.category == .appointment || $0.category == .test) && $0.dayKey >= todayKey }
            .sorted { $0.dayKey < $1.dayKey }
            .first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Clinical Care Plan Banner
                clinicalCareCard

                // MARK: - Missed Appointment Alert Banner (if any)
                if !missedReports.isEmpty {
                    missedAppointmentAlertBanner
                }

                // MARK: - Calendar Header & Month Navigation
                CalendarHeaderView {
                    selectedDate = Date()
                    displayedMonth = LocalDay.startOfMonth(for: selectedDate)
                }

                // MARK: - Month Grid View
                MonthCalendarView(
                    store: store,
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate
                )

                // MARK: - Daily Mood Tracker
                DayMoodTrackerView(
                    store: store,
                    dayKey: selectedDayKey
                )

                // MARK: - Daily Checkpoints
                DayCheckpointsView(
                    store: store,
                    dayKey: selectedDayKey
                )

                // MARK: - Day Timeline View
                DayTimelineView(
                    store: store,
                    dayKey: selectedDayKey,
                    onAddEntry: { showingAddEntry = true },
                    onSelectEntry: { selectedEntry = CalendarEntrySelection(id: $0) }
                )

                // MARK: - Upcoming Section
                UpcomingSectionView(store: store) {
                    selectedEntry = CalendarEntrySelection(id: $0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Your Journey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingCarePlanSheet = true
                } label: {
                    Label("Care Plan", systemImage: "cross.case")
                        .font(.subheadline.weight(.semibold))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Add a journal entry")
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntrySheet(store: store, date: selectedDate)
        }
        .sheet(isPresented: $showingCarePlanSheet) {
            ClinicalCarePlanView(store: store, onboardingStore: onboardingStore)
        }
        .sheet(item: $selectedEntry) { selection in
            NavigationStack {
                EntryDetailView(store: store, entryID: selection.id)
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { store.clearError() }
        } message: {
            Text(store.lastErrorMessage ?? "Please try again.")
        }
        .onChange(of: selectedDate) { newDate in
            let month = LocalDay.startOfMonth(for: newDate)
            if month != displayedMonth {
                displayedMonth = month
            }
        }
        .onAppear {
            syncClinicalCarePlan()
        }
        .onChange(of: onboardingStore.profile) { _ in
            syncClinicalCarePlan()
        }
    }

    // MARK: - Clinical Care Card

    private var clinicalCareCard: some View {
        Button {
            showingCarePlanSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "cross.case.fill")
                    .font(.title3)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 44, height: 44)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(profile?.stage == .pregnant ? "Week \(currentWeek) • Clinical Care Plan" : "Clinical Care Plan")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AccentColor"))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    if let next = nextClinicalMilestone {
                        Text(next.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("Scheduled for \(LocalDay.dateText(for: next.dayKey, style: .abbreviated))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("All upcoming hospital visits and sonograms are planned.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Missed Appointment Alert Banner

    private var missedAppointmentAlertBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(missedReports.count) Missed Appointment\(missedReports.count > 1 ? "s" : "") / Test\(missedReports.count > 1 ? "s" : "")")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    if let first = missedReports.first {
                        Text("\(first.entry.title) was scheduled for \(LocalDay.dateText(for: first.entry.dayKey)).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    _ = MaternalSchedulePlanner.shared.smartReviseAllMissedEntries(in: store)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Auto-Revise Schedule")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
                }

                Button {
                    showingCarePlanSheet = true
                } label: {
                    Text("Review Details")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1.2)
        )
    }

    // MARK: - Sync Helper

    private func syncClinicalCarePlan() {
        guard let profile = onboardingStore.profile else { return }
        MaternalSchedulePlanner.shared.syncSchedule(into: store, profile: profile, forceRegenerate: false)
    }
}

struct CalendarEntrySelection: Identifiable {
    let id: UUID
}
