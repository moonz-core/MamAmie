import SwiftUI

struct RecommendedActivity: Identifiable, Hashable {
    let id: String
    let title: String
    let iconName: String
    let subtitle: String
}

struct DayCheckpointsView: View {
    @ObservedObject var store: JournalStore
    let dayKey: String

    @AppStorage("mamamie_daily_checkpoints_enabled") private var checkpointsEnabled: Bool = true
    @State private var showingCustomDialog = false
    @State private var customActivityTitle = ""

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

    private var dayTasks: [CalendarEntry] {
        store.entries(for: dayKey).filter { $0.category == .task }
    }

    private var completedCount: Int {
        dayTasks.filter { $0.task?.completed == true }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .alert("Add Custom Daily Activity", isPresented: $showingCustomDialog) {
            TextField("e.g. Coconut water, Swimming, Meditation", text: $customActivityTitle)
            Button("Add to Today") {
                if !customActivityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    addCheckpoint(title: customActivityTitle.trimmingCharacters(in: .whitespaces))
                    customActivityTitle = ""
                }
            }
            Button("Cancel", role: .cancel) {
                customActivityTitle = ""
            }
        } message: {
            Text("Enter a personal daily wellness habit you want to track for this day.")
        }
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
                Section("Recommended by MamAmie") {
                    ForEach(Self.recommendations) { rec in
                        Button {
                            addCheckpoint(title: rec.title, notes: rec.subtitle)
                        } label: {
                            Label(rec.title, systemImage: rec.iconName)
                        }
                    }
                }

                Divider()

                Button {
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

    // MARK: - Actions

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

    private func addCheckpoint(title: String, notes: String = "Daily wellness checkpoint") {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let now = Date()
        let newEntry = CalendarEntry(
            id: UUID(),
            title: title,
            category: .task,
            dayKey: dayKey,
            timeMinutes: LocalDay.minutes(for: now),
            notes: notes,
            createdAt: now,
            modifiedAt: now,
            attachments: [],
            task: TaskDetails(completed: false)
        )
        store.upsertEntry(newEntry)
    }

    private func seedRecommendedDefaults() {
        let essentials = [
            Self.recommendations[0], // Water
            Self.recommendations[1], // Steps
            Self.recommendations[2], // Prenatal vitamin
            Self.recommendations[3]  // Sunlight
        ]

        let existingTitles = Set(dayTasks.map(\.title))
        for item in essentials where !existingTitles.contains(item.title) {
            addCheckpoint(title: item.title, notes: item.subtitle)
        }
    }
}
