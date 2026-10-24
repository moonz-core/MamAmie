import SwiftUI

struct RecommendedActivity: Identifiable, Hashable {
    let id: String
    let title: String
    let iconName: String
    let subtitle: String
}

struct DayCheckpointsView: View {
    @ObservedObject var store: JournalStore
    let profile: OnboardingProfile?
    let dayKey: String

    @AppStorage("mamamie_daily_checkpoints_enabled") private var checkpointsEnabled: Bool = true
    @AppStorage("mamamie_active_daily_habits") private var activeDailyHabitsString: String = "Drink 2.5L Water (8–10 cups)|Walk 4,000 gentle steps (20–30 min)|Take prenatal vitamin & iron supplement|15 min morning sunlight & Vitamin D"

    @State private var showingCustomDialog = false
    @State private var customActivityTitle = ""
    @State private var repeatEveryDay = true

    // AI Adaptation State
    @State private var aiAdaptation: AIExerciseAdaptationResult?
    @State private var isLoadingAIAdaptation = false
    @State private var isAIPlanApplied = false

    static let recommendations: [RecommendedActivity] = [
        RecommendedActivity(
            id: "water_goal",
            title: "Drink 2.5L Water (8–10 cups)",
            iconName: "drop.fill",
            subtitle: "Maintains amniotic fluid & prevents contractions"
        ),
        RecommendedActivity(
            id: "steps_goal",
            title: "Walk 4,000 gentle steps (20–30 min)",
            iconName: "figure.walk",
            subtitle: "ACOG moderate aerobic movement goal"
        ),
        RecommendedActivity(
            id: "prenatal_vitamin",
            title: "Take prenatal vitamin & iron supplement",
            iconName: "pill.fill",
            subtitle: "Supports neural tube & red blood cells"
        ),
        RecommendedActivity(
            id: "sunlight_vit_d",
            title: "15 min morning sunlight & Vitamin D",
            iconName: "sun.max.fill",
            subtitle: "Aids fetal bone & teeth mineralization"
        ),
        RecommendedActivity(
            id: "leg_elevation",
            title: "Elevate legs for 15 mins (swelling relief)",
            iconName: "bed.double.fill",
            subtitle: "Eases ankle edema & venous return"
        ),
        RecommendedActivity(
            id: "kegels",
            title: "Pelvic floor (Kegel) gentle exercises",
            iconName: "waveform.path.ecg",
            subtitle: "Strengthens perineum for labor & postpartum"
        ),
        RecommendedActivity(
            id: "left_side_sleep",
            title: "Left-side sleep posture with knee pillow",
            iconName: "moon.fill",
            subtitle: "Maximizes placental blood & oxygen flow"
        ),
        RecommendedActivity(
            id: "kick_counts",
            title: "Count 10 fetal kicks in baby's active window",
            iconName: "heart.fill",
            subtitle: "Third trimester daily movement check"
        ),
        RecommendedActivity(
            id: "prenatal_stretch",
            title: "10 mins hip-opening & cat-cow stretches",
            iconName: "figure.mind.and.body",
            subtitle: "Relieves SI joint and lower back tension"
        )
    ]

    private var activeDailyHabits: [String] {
        activeDailyHabitsString.components(separatedBy: "|").filter { !$0.isEmpty }
    }

    private var dayTasks: [CalendarEntry] {
        store.entries(for: dayKey).filter { $0.category == .task }
    }

    private var completedCount: Int {
        dayTasks.filter { $0.task?.completed == true }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))

                    Text("Daily Wellness Checkpoints")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                if checkpointsEnabled {
                    if !dayTasks.isEmpty {
                        Text("\(completedCount)/\(dayTasks.count) done")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(completedCount == dayTasks.count && !dayTasks.isEmpty ? .green : Color("AccentColor"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((completedCount == dayTasks.count && !dayTasks.isEmpty ? Color.green : Color("AccentColor")).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Menu {
                        Button(role: .destructive) {
                            withAnimation { checkpointsEnabled = false }
                        } label: {
                            Label("Turn Off Checkpoints", systemImage: "eye.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
                } else {
                    Button("Turn On") {
                        withAnimation { checkpointsEnabled = true }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                }
            }

            if !checkpointsEnabled {
                HStack {
                    Text("Daily checkpoints are hidden. Tap 'Turn On' anytime to track your daily habits.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                // MARK: - AI Exercise Coach Card (if fatigue or skipped exercises detected)
                if let ai = aiAdaptation, !isAIPlanApplied {
                    aiCoachCard(ai)
                }

                // Checkpoint Items List
                if dayTasks.isEmpty {
                    emptyCheckpointsState
                } else {
                    VStack(spacing: 8) {
                        ForEach(dayTasks) { task in
                            checkpointRow(task)
                        }
                    }
                }

                // Add Activity Bar (Dropdown + Custom)
                addActivityBar
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            ensureRecurringHabitsExist()
            checkForAIExerciseAdaptation()
        }
        .onChange(of: dayKey) { _ in
            ensureRecurringHabitsExist()
            checkForAIExerciseAdaptation()
        }
        .sheet(isPresented: $showingCustomDialog) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Add Custom Daily Activity")
                        .font(.headline)
                        .padding(.top, 16)

                    TextField("e.g. Coconut water, 15 min swim, Meditation", text: $customActivityTitle)
                        .font(.subheadline)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Toggle("Repeat for Every Day", isOn: $repeatEveryDay)
                        .font(.subheadline.weight(.medium))
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Spacer()

                    Button {
                        let trimmed = customActivityTitle.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            addCheckpoint(title: trimmed, repeatDaily: repeatEveryDay)
                            customActivityTitle = ""
                            showingCustomDialog = false
                        }
                    } label: {
                        Text("Add Activity")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .navigationTitle("Custom Activity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingCustomDialog = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - AI Coach Card Component

    private func aiCoachCard(_ ai: AIExerciseAdaptationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.pink)

                Text("AI Maternal Exercise Coach")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            Text(ai.observation)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Gentle Alternatives:")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.primary)

                ForEach(ai.adaptedExercises, id: \.self) { ex in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(ex)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)

            HStack {
                Text(ai.coachAffirmation)
                    .font(.caption2.italic())
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    applyAIPlan(ai)
                } label: {
                    Text("Apply Gentle Plan")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.pink)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color.pink.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Row Component

    private func checkpointRow(_ entry: CalendarEntry) -> some View {
        let isCompleted = entry.task?.completed == true

        return HStack(spacing: 12) {
            Button {
                toggleTask(entry)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                if !entry.notes.isEmpty && entry.notes != "Daily wellness checkpoint" {
                    Text(entry.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                deleteTask(entry)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }

    // MARK: - Empty State

    private var emptyCheckpointsState: some View {
        VStack(spacing: 8) {
            Text("No checkpoints added for this day yet.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                seedRecommendedDefaults()
            } label: {
                Label("Add Recommended Daily Habits", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Add Activity Bar

    private var addActivityBar: some View {
        HStack(spacing: 10) {
            // Dropdown Menu with Recommended Items
            Menu {
                Section("Recommended for Every Day") {
                    ForEach(Self.recommendations) { rec in
                        Button {
                            addCheckpoint(title: rec.title, notes: rec.subtitle, repeatDaily: true)
                        } label: {
                            Label(rec.title, systemImage: rec.iconName)
                        }
                    }
                }

                Divider()

                Button {
                    repeatEveryDay = true
                    showingCustomDialog = true
                } label: {
                    Label("Create Custom Activity...", systemImage: "plus.circle")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Activity")
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AccentColor"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("AccentColor").opacity(0.12))
                .cornerRadius(8)
            }

            Spacer()

            if dayTasks.count < 3 {
                Button {
                    seedRecommendedDefaults()
                } label: {
                    Text("Pre-fill Essentials")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Actions & Persistence

    private func toggleTask(_ entry: CalendarEntry) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var updated = entry
        let currentStatus = entry.task?.completed ?? false
        updated.task = TaskDetails(completed: !currentStatus)
        updated.modifiedAt = Date()
        store.upsertEntry(updated)
    }

    private func deleteTask(_ entry: CalendarEntry) {
        store.deleteEntry(id: entry.id)
    }

    private func addCheckpoint(title: String, notes: String = "Daily wellness checkpoint", repeatDaily: Bool = true) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let now = Date()

        if repeatDaily {
            // Add to active daily habits template so it stays across all days
            var habits = activeDailyHabits
            if !habits.contains(title) {
                habits.append(title)
                activeDailyHabitsString = habits.joined(separator: "|")
            }

            // Populate forward across the current and next 30 days
            let calendar = LocalDay.calendar
            if let baseDate = LocalDay.date(from: dayKey) {
                for offset in 0..<30 {
                    guard let targetDate = calendar.date(byAdding: .day, value: offset, to: baseDate) else { continue }
                    let targetKey = LocalDay.key(for: targetDate)
                    let existingForTarget = store.entries(for: targetKey)
                    if !existingForTarget.contains(where: { $0.title == title }) {
                        let entry = CalendarEntry(
                            id: UUID(),
                            title: title,
                            category: .task,
                            dayKey: targetKey,
                            timeMinutes: LocalDay.minutes(for: now),
                            notes: notes,
                            createdAt: now,
                            modifiedAt: now,
                            task: TaskDetails(completed: false)
                        )
                        store.upsertEntry(entry)
                    }
                }
            }
        } else {
            // One-day only
            let newEntry = CalendarEntry(
                id: UUID(),
                title: title,
                category: .task,
                dayKey: dayKey,
                timeMinutes: LocalDay.minutes(for: now),
                notes: notes,
                createdAt: now,
                modifiedAt: now,
                task: TaskDetails(completed: false)
            )
            store.upsertEntry(newEntry)
        }
    }

    private func ensureRecurringHabitsExist() {
        guard checkpointsEnabled else { return }
        let existingTitles = Set(dayTasks.map(\.title))
        let now = Date()

        for habit in activeDailyHabits {
            if !existingTitles.contains(habit) {
                let entry = CalendarEntry(
                    id: UUID(),
                    title: habit,
                    category: .task,
                    dayKey: dayKey,
                    timeMinutes: 480,
                    notes: "Daily wellness checkpoint",
                    createdAt: now,
                    modifiedAt: now,
                    task: TaskDetails(completed: false)
                )
                store.upsertEntry(entry)
            }
        }
    }

    private func seedRecommendedDefaults() {
        let essentials = [
            Self.recommendations[0].title, // Water
            Self.recommendations[1].title, // Steps
            Self.recommendations[2].title, // Prenatal vitamin
            Self.recommendations[3].title  // Sunlight
        ]

        var habits = activeDailyHabits
        for item in essentials where !habits.contains(item) {
            habits.append(item)
        }
        activeDailyHabitsString = habits.joined(separator: "|")
        ensureRecurringHabitsExist()
    }

    private func checkForAIExerciseAdaptation() {
        Task {
            let result = await AIExerciseAdaptationService.shared.evaluateAndAdapt(
                store: store,
                profile: profile,
                todayKey: dayKey
            )
            await MainActor.run {
                self.aiAdaptation = result
            }
        }
    }

    private func applyAIPlan(_ ai: AIExerciseAdaptationResult) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let now = Date()

        // Replace or adjust demanding walk/steps task for today
        for task in dayTasks {
            let lower = task.title.lowercased()
            if lower.contains("walk") || lower.contains("step") {
                var updated = task
                updated.notes = "[Adapted by AI Coach]: Replaced with gentle restorative movements."
                updated.task = TaskDetails(completed: true) // mark high exertion as completed/resolved
                store.upsertEntry(updated)
            }
        }

        // Add the adapted gentle exercises
        for exercise in ai.adaptedExercises {
            let entry = CalendarEntry(
                id: UUID(),
                title: "✨ " + exercise,
                category: .task,
                dayKey: dayKey,
                timeMinutes: LocalDay.minutes(for: now),
                notes: "Tailored gentle movement recommended by your AI Exercise Coach.",
                createdAt: now,
                modifiedAt: now,
                task: TaskDetails(completed: false)
            )
            store.upsertEntry(entry)
        }

        withAnimation {
            isAIPlanApplied = true
        }
    }
}
