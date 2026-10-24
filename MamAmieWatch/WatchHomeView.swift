import Charts
import SwiftUI

struct WatchHomeView: View {
    @ObservedObject var store: WatchCompanionStore
    @ObservedObject var heartRate: WatchHeartRateService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your care, close at hand.")
                            .font(.headline)
                            .foregroundStyle(Color("AccentColor"))
                        Text("Quick tools for your day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)

                    heartRateCard
                    appointmentCard
                    medicationCard

                    NavigationLink {
                        WatchKickCounterView(store: store)
                    } label: {
                        WatchActionCard(title: "Movement counter", detail: "Count at your own pace", symbol: "figure.walk", tint: Color("AccentColor"))
                    }
                    NavigationLink {
                        WatchContractionTimerView(store: store)
                    } label: {
                        WatchActionCard(title: "Contraction timer", detail: "Time and review a session", symbol: "timer", tint: .orange)
                    }
                    NavigationLink {
                        WatchHydrationView(store: store)
                    } label: {
                        WatchActionCard(title: "Water log", detail: "Record a serving", symbol: "drop.fill", tint: .cyan)
                    }
                    NavigationLink {
                        WatchMedicationListView(store: store)
                    } label: {
                        WatchActionCard(title: "Care reminders", detail: "View and log scheduled doses", symbol: "pills.fill", tint: .purple)
                    }
                    NavigationLink {
                        WatchQuickCareView(store: store)
                    } label: {
                        WatchActionCard(title: "Quick care notes", detail: "Optional postpartum and newborn logs", symbol: "heart.fill", tint: .pink)
                    }

                    Text(store.connectionDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if store.pendingActionCount > 0 {
                        Text("Watch entries stay on this watch until the phone confirms receipt.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button("Refresh phone details") { store.requestFreshSnapshot() }
                        .font(.caption.weight(.semibold))
                        .tint(Color("AccentColor"))
                    if store.pendingActionCount > 0 {
                        Button("Retry pending sync") { store.retryPendingSync() }
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .navigationTitle("MamAmie")
        }
    }

    private var heartRateCard: some View {
        NavigationLink {
            WatchHeartRateView(service: heartRate)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label("Your heart rate", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AccentColor"))
                if let bpm = heartRate.latestBPM, let date = heartRate.latestDate {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(bpm.rounded()))").font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("BPM").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Apple Health · \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Open for your latest Apple Health reading")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color("AccentColor").opacity(0.11), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var appointmentCard: some View {
        Group {
            if let appointment = store.snapshot?.appointments.first {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Next appointment", systemImage: "calendar")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                    Text(appointment.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                    Text(appointment.dateText)
                        .font(.caption).foregroundStyle(.secondary)
                    if let location = appointment.location, !location.isEmpty {
                        Text(location).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var medicationCard: some View {
        Group {
            if let medication = store.snapshot?.medications.first {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Next scheduled dose", systemImage: "pills.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(.purple)
                    Text(medication.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text([medication.dose, medication.dateText]
                        .filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private extension WatchAppointment {
    var dateText: String {
        guard let timeMinutes else { return date.formatted(date: .abbreviated, time: .omitted) }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = timeMinutes / 60
        components.minute = timeMinutes % 60
        return (Calendar.current.date(from: components) ?? date)
            .formatted(date: .abbreviated, time: .shortened)
    }
}

private extension WatchMedication {
    var dateText: String {
        guard let timeMinutes else { return scheduledDate.formatted(date: .abbreviated, time: .omitted) }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: scheduledDate)
        components.hour = timeMinutes / 60
        components.minute = timeMinutes % 60
        return (Calendar.current.date(from: components) ?? scheduledDate)
            .formatted(date: .abbreviated, time: .shortened)
    }
}

struct WatchActionCard: View {
    var title: String
    var detail: String
    var symbol: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.headline).foregroundStyle(tint).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
        }
        .padding(11)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct WatchHeartRateView: View {
    @ObservedObject var service: WatchHeartRateService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Your heart rate", systemImage: "heart.fill")
                    .font(.headline).foregroundStyle(Color("AccentColor"))
                Text("This is your heart rate from Apple Health. Apple Watch heart-rate readings are not fetal heart-rate measurements or a medical monitor.")
                    .font(.caption).foregroundStyle(.secondary)

                switch service.state {
                case .notRequested:
                    Text("Allow MamAmie to read heart-rate samples from Apple Health. You can change access in Settings.")
                        .font(.caption)
                    Button("Allow heart-rate access") { Task { await service.requestAccessAndRefresh() } }
                        .buttonStyle(.borderedProminent).tint(Color("AccentColor"))
                case .loading:
                    ProgressView("Checking Apple Health…")
                case .available:
                    if let bpm = service.latestBPM, let date = service.latestDate {
                        Text("\(Int(bpm.rounded())) BPM")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Most recent sample · \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                        freshness(for: date)
                        if service.trend.count > 1 {
                            Chart(service.trend) { point in
                                LineMark(x: .value("Time", point.date), y: .value("BPM", point.beatsPerMinute))
                                    .foregroundStyle(Color("AccentColor"))
                                PointMark(x: .value("Time", point.date), y: .value("BPM", point.beatsPerMinute))
                                    .foregroundStyle(Color("AccentColor"))
                            }
                            .frame(height: 90)
                            .accessibilityLabel("Heart-rate samples from the last 24 hours")
                        }
                    }
                    Button("Refresh") { Task { await service.refresh() } }.buttonStyle(.bordered)
                case .noData:
                    Text("No recent heart-rate samples were found. Access may also be unavailable in Apple Health settings.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Check again") { Task { await service.refresh() } }.buttonStyle(.bordered)
                case .unavailable:
                    Text("HealthKit is unavailable on this device.").font(.caption).foregroundStyle(.secondary)
                case .error:
                    Text("MamAmie couldn’t read Apple Health right now. Your care details remain available.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Try again") { Task { await service.refresh() } }.buttonStyle(.bordered)
                }
            }
            .padding(12)
        }
        .navigationTitle("Heart rate")
        .task {
            if service.state == .noData || service.state == .available {
                await service.refresh()
            }
        }
    }

    @ViewBuilder
    private func freshness(for date: Date) -> some View {
        let age = Date().timeIntervalSince(date)
        Text(age < 60 * 60 ? "Recent reading" : "Historical reading")
            .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
    }
}
