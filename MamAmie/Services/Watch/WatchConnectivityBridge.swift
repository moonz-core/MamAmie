import Combine
import Foundation
import WatchConnectivity

/// Phone-side bridge: publishes the latest care schedule and accepts durable watch actions.
final class WatchConnectivityBridge: NSObject, ObservableObject {
    @Published private(set) var isSupported = WCSession.isSupported()
    @Published private(set) var lastActionSyncAt: Date?

    private var journalStore: JournalStore?
    private let activityPersistence = WatchActivityPersistence()
    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    func activate(journalStore: JournalStore) {
        self.journalStore = journalStore
        guard let session else { return }
        session.delegate = self
        session.activate()
        publishLatestSnapshot()
    }

    func publishLatestSnapshot() {
        guard let session, session.activationState == .activated,
              let journalStore,
              let data = try? JSONEncoder().encode(makeSnapshot(from: journalStore)) else { return }
        do {
            try session.updateApplicationContext(["snapshot": data])
        } catch {
            // A later store change or session activation will retry the latest snapshot.
        }
    }

    private func makeSnapshot(from store: JournalStore) -> WatchCompanionSnapshot {
        let upcoming = store.upcomingEntries(from: LocalDay.key(for: Date()), limit: 24)
        let appointments = upcoming.compactMap { entry -> WatchAppointment? in
            guard entry.category == .appointment,
                  let appointment = entry.appointment,
                  appointment.status != .completed,
                  appointment.status != .cancelled,
                  let date = LocalDay.date(from: entry.dayKey) else { return nil }
            return WatchAppointment(
                id: entry.id.uuidString,
                title: entry.title,
                date: date,
                timeMinutes: entry.timeMinutes,
                location: appointment.clinicianOrClinic.isEmpty ? nil : appointment.clinicianOrClinic
            )
        }

        let medications = upcoming.compactMap { entry -> WatchMedication? in
            guard entry.category == .medication,
                  let schedule = store.medicationSchedule(for: entry),
                  let date = LocalDay.date(from: entry.dayKey) else { return nil }
            return WatchMedication(
                id: entry.id.uuidString,
                scheduleID: schedule.id.uuidString,
                name: schedule.name,
                dose: schedule.dose,
                instructions: schedule.instructions,
                scheduledDate: date,
                timeMinutes: entry.timeMinutes
            )
        }
        return WatchCompanionSnapshot(
            updatedAt: Date(),
            appointments: Array(appointments.prefix(4)),
            medications: Array(medications.prefix(8))
        )
    }

    private func receive(_ action: WatchCompanionAction, from session: WCSession) {
        if action.kind == .medicationDose {
            guard let scheduleID = action.scheduleID,
                  let scheduleUUID = UUID(uuidString: scheduleID),
                  let occurrenceID = action.occurrenceID,
                  let occurrenceUUID = UUID(uuidString: occurrenceID),
                  let store = journalStore,
                  let entry = store.entries.first(where: {
                      $0.id == occurrenceUUID && $0.medicationID == scheduleUUID
                  }),
                  let statusValue = action.doseStatus,
                  let status = DoseStatus(rawValue: statusValue),
                  store.logDose(
                    for: entry,
                    status: status,
                    notes: "Recorded on Apple Watch",
                    id: action.id,
                    actualLoggedAt: action.occurredAt,
                    dayKey: action.dayKey
                  ) else { return }
        }
        guard activityPersistence.appendIfNeeded(action) else { return }
        DispatchQueue.main.async { self.lastActionSyncAt = Date() }
        if session.activationState == .activated {
            session.transferUserInfo(["acknowledgedActionID": action.id.uuidString])
        }
    }
}

extension WatchConnectivityBridge: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.publishLatestSnapshot() }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        guard message["requestSnapshot"] as? Bool == true else {
            replyHandler(["unavailable": true])
            return
        }
        DispatchQueue.main.async {
            guard let journalStore = self.journalStore,
                  let data = try? JSONEncoder().encode(self.makeSnapshot(from: journalStore)) else {
                replyHandler(["unavailable": true])
                return
            }
            replyHandler(["snapshot": data])
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["action"] as? Data,
              let action = try? JSONDecoder().decode(WatchCompanionAction.self, from: data) else { return }
        DispatchQueue.main.async { self.receive(action, from: session) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
