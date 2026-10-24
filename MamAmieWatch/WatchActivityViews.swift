import SwiftUI
import WatchKit

struct WatchKickCounterView: View {
    @ObservedObject var store: WatchCompanionStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Movement counter").font(.headline).foregroundStyle(Color("AccentColor"))
                if let startedAt = store.localState.activeKickStartedAt {
                    Text(startedAt, style: .timer)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .accessibilityLabel("Session elapsed time")
                    Text("\(store.localState.activeKickCount)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .accessibilityLabel("\(store.localState.activeKickCount) movements recorded")
                    Button {
                        store.recordMovement()
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Label("Record movement", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent).tint(Color("AccentColor"))
                    Button("Finish session") { store.finishMovementSession() }
                        .buttonStyle(.bordered)
                } else {
                    Text("Use the counting method your clinician recommended. There is no universal target in this counter.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Start counting") {
                        store.startMovementSession()
                        WKInterfaceDevice.current().play(.start)
                    }
                    .buttonStyle(.borderedProminent).tint(Color("AccentColor"))
                }

                Text("A movement session cannot confirm fetal wellbeing. If movement is reduced or concerning to you, contact your maternity team now; do not wait to finish counting.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !store.lastMovementSessions.isEmpty {
                    Divider()
                    Text("Recent sessions").font(.caption.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(store.lastMovementSessions) { session in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.movementCount) movements").font(.subheadline.weight(.semibold))
                            Text(session.endedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle("Movement")
    }
}

struct WatchContractionTimerView: View {
    @ObservedObject var store: WatchCompanionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Contraction timer").font(.headline).foregroundStyle(Color("AccentColor"))
                if let startedAt = store.localState.activeContractionStartedAt {
                    Text("Timing now")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(startedAt, style: .timer)
                        .font(.system(size: 31, weight: .bold, design: .rounded).monospacedDigit())
                    Button {
                        store.stopContraction()
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Label("Stop contraction", systemImage: "stop.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(.orange)
                } else {
                    Button {
                        store.startContraction()
                        WKInterfaceDevice.current().play(.start)
                    } label: {
                        Label("Start contraction", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).tint(.orange)
                }

                if !store.localState.currentContractions.isEmpty {
                    Text("This session").font(.caption.weight(.semibold))
                    ForEach(Array(store.localState.currentContractions.enumerated()), id: \.element.id) { index, record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(index + 1) · \(formatDuration(record.durationSeconds))")
                                .font(.subheadline.weight(.semibold))
                            if let interval = record.intervalSeconds {
                                Text("Start-to-start interval: \(formatDuration(interval))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Finish session and save") { store.finishContractionSession() }
                        .buttonStyle(.bordered)
                }

                Text("Follow your maternity team's instructions. Timing is for your notes and is not a diagnosis or a reason to delay urgent care.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let recent = store.lastContractionSessions.first {
                    Divider()
                    Text("Last saved session · \(recent.endedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption.weight(.semibold))
                    ForEach(Array(recent.records.enumerated()), id: \.element.id) { index, record in
                        Text("\(index + 1): \(formatDuration(record.durationSeconds))" +
                             (record.intervalSeconds.map { " · interval \(formatDuration($0))" } ?? ""))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle("Contractions")
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes == 0 ? "\(remainder)s" : "\(minutes)m \(remainder)s"
    }
}

struct WatchHydrationView: View {
    @ObservedObject var store: WatchCompanionStore
    @State private var goalDraft = -1

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Water log").font(.headline).foregroundStyle(Color("AccentColor"))
                if let target = store.localState.hydrationTargetML {
                    ProgressView(value: Double(store.waterTodayML), total: Double(target))
                        .tint(Color("AccentColor"))
                        .accessibilityLabel("Water intake progress")
                    Text("\(store.waterTodayML) / \(target) mL")
                        .font(.title3.weight(.bold).monospacedDigit())
                } else {
                    Text("\(store.waterTodayML) mL recorded today")
                        .font(.title3.weight(.bold).monospacedDigit())
                    Text("No daily target is set. Use a goal from your clinician or your own preference.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Button {
                    store.addWater()
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Label("Add \(store.localState.hydrationServingML) mL", systemImage: "drop.fill")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(.cyan)
                Button("Undo last serving") { store.undoWater() }
                    .buttonStyle(.bordered).disabled(store.waterTodayML == 0)

                Stepper(value: Binding(
                    get: { store.localState.hydrationServingML },
                    set: { store.setHydrationServing($0) }
                ), in: 50...1000, step: 50) {
                    Text("Serving: \(store.localState.hydrationServingML) mL")
                        .font(.caption2)
                }

                Divider()
                if let target = store.localState.hydrationTargetML {
                    Text("Personal target: \(target) mL")
                        .font(.caption2).foregroundStyle(.secondary)
                    Button("Change or clear target") { goalDraft = target }
                        .buttonStyle(.bordered)
                } else {
                    Button("Set a personal target") { goalDraft = 0 }
                        .buttonStyle(.bordered)
                }
                if goalDraft >= 0 {
                    Stepper(value: $goalDraft, in: 0...6000, step: 250) {
                        Text(goalDraft == 0 ? "No target" : "Goal: \(goalDraft) mL")
                            .font(.caption2)
                    }
                    Button("Save") { store.setHydrationTarget(goalDraft == 0 ? nil : goalDraft); goalDraft = -1 }
                        .buttonStyle(.borderedProminent).tint(Color("AccentColor"))
                    Button("Cancel") { goalDraft = -1 }.buttonStyle(.plain)
                }
                Text("Intake is user-recorded. This tracker does not prescribe a hydration goal.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .onAppear { goalDraft = -1 }
        .navigationTitle("Hydration")
    }
}

struct WatchMedicationListView: View {
    @ObservedObject var store: WatchCompanionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Scheduled care").font(.headline).foregroundStyle(Color("AccentColor"))
                if let snapshot = store.snapshot {
                    if snapshot.medications.isEmpty {
                        Text("No upcoming medication entries were shared from your iPhone.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.medications) { medication in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(medication.name).font(.subheadline.weight(.semibold))
                            if !medication.dose.isEmpty { Text(medication.dose).font(.caption) }
                            if !medication.instructions.isEmpty {
                                Text(medication.instructions).font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(medication.dateText)
                                .font(.caption2).foregroundStyle(.secondary)
                            if store.hasDoseLog(for: medication.id) {
                                Text("A status was recorded for this entry")
                                    .font(.caption2.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                            } else {
                                HStack(spacing: 6) {
                                    Button("Taken") { store.recordDose(medication, status: DoseStatus.taken.rawValue) }
                                        .buttonStyle(.borderedProminent).tint(Color("AccentColor"))
                                    Button("Skipped") { store.recordDose(medication, status: DoseStatus.skipped.rawValue) }
                                        .buttonStyle(.bordered)
                                }
                                Button("Not confirmed") {
                                    store.recordDose(medication, status: DoseStatus.notConfirmed.rawValue)
                                }
                                .font(.caption2.weight(.semibold))
                                .buttonStyle(.plain)
                            }
                            Text("Dose status is your report, not proof of ingestion.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color("AccentColor").opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Text("Open MamAmie on iPhone to share scheduled care details. No reminder schedule is available offline yet.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Try sync") { store.requestFreshSnapshot() }.buttonStyle(.bordered)
                }
                if store.pendingActionCount > 0 {
                    Text("Your dose log is saved on this watch and waiting for phone confirmation.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }.padding(12)
        }
        .navigationTitle("Care reminders")
    }
}

struct WatchQuickCareView: View {
    @ObservedObject var store: WatchCompanionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text("Quick care note").font(.headline).foregroundStyle(Color("AccentColor"))
                Text("Optional postpartum and newborn logs, if relevant to you.")
                    .font(.caption).foregroundStyle(.secondary)
                quickLog("Feeding started", symbol: "drop.fill", kind: .feeding)
                quickLog("Diaper changed", symbol: "heart.fill", kind: .diaper)
                quickLog("Recovery check-in", symbol: "heart.fill", kind: .recoveryCheckIn)
                Text("Notes are saved on this watch and queued for phone sync. They are organizational tools, not medical monitoring.")
                    .font(.caption2).foregroundStyle(.secondary)
            }.padding(12)
        }
        .navigationTitle("Quick care")
    }

    private func quickLog(_ title: String, symbol: String, kind: WatchActionKind) -> some View {
        Button {
            store.recordQuickCare(kind)
            WKInterfaceDevice.current().play(.click)
        } label: {
            Label(title, systemImage: symbol).frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
