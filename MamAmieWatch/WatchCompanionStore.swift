import Combine
import Foundation
import WatchConnectivity

struct WatchMovementSession: Codable, Identifiable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var movementCount: Int
}

struct WatchContractionRecord: Codable, Identifiable {
    var id: UUID
    var startedAt: Date
    var durationSeconds: Int
    var intervalSeconds: Int?
}

struct WatchContractionSession: Codable, Identifiable {
    var id: UUID
    var endedAt: Date
    var records: [WatchContractionRecord]
}

struct WatchLocalState: Codable {
    var actions: [WatchCompanionAction] = []
    var pendingActionIDs: [UUID] = []
    var activeKickStartedAt: Date?
    var activeKickCount = 0
    var kickHistory: [WatchMovementSession] = []
    var activeContractionStartedAt: Date?
    var currentContractions: [WatchContractionRecord] = []
    var previousContractionEnd: Date?
    var contractionHistory: [WatchContractionSession] = []
    var hydrationServingML = 200
    var hydrationTargetML: Int?
}

final class WatchCompanionStore: NSObject, ObservableObject {
    @Published private(set) var snapshot: WatchCompanionSnapshot?
    @Published private(set) var connectionDescription = "Waiting for iPhone details"
    @Published private(set) var lastAcknowledgedAt: Date?
    @Published private(set) var localState: WatchLocalState

    private let stateKey = "mamamie.watch.local-state.v1"
    private var session: WCSession? { WCSession.isSupported() ? .default : nil }
    private var sentActionIDs = Set<UUID>()

    override init() {
        if let data = UserDefaults.standard.data(forKey: "mamamie.watch.local-state.v1"),
           let decoded = try? JSONDecoder().decode(WatchLocalState.self, from: data) {
            localState = decoded
        } else {
            localState = WatchLocalState()
        }
        super.init()
        apply(session?.receivedApplicationContext ?? [:])
    }

    var pendingActionCount: Int { localState.pendingActionIDs.count }
    func hasDoseLog(for occurrenceID: String) -> Bool {
        localState.actions.contains { $0.kind == .medicationDose && $0.occurrenceID == occurrenceID }
    }

    var waterTodayML: Int {
        let today = LocalDay.key(for: Date())
        return max(0, localState.actions
            .filter { $0.kind == .hydration && $0.dayKey == today }
            .compactMap(\.amountMillilitres)
            .reduce(0, +))
    }

    var lastMovementSessions: [WatchMovementSession] { Array(localState.kickHistory.suffix(3).reversed()) }
    var lastContractionSessions: [WatchContractionSession] { Array(localState.contractionHistory.suffix(3).reversed()) }

    func activate() {
        guard let session else {
            connectionDescription = "Watch and iPhone sync is unavailable on this device"
            return
        }
        session.delegate = self
        session.activate()
        apply(session.receivedApplicationContext)
        requestFreshSnapshot()
        flushPendingActions()
    }

    func requestFreshSnapshot() {
        guard let session, session.activationState == .activated else { return }
        guard session.isReachable else {
            if snapshot == nil { connectionDescription = "Open MamAmie on iPhone to share care details" }
            return
        }
        session.sendMessage(["requestSnapshot": true], replyHandler: { [weak self] reply in
            self?.apply(reply)
        }, errorHandler: { [weak self] _ in
            DispatchQueue.main.async { self?.connectionDescription = "Phone details may be out of date" }
        })
    }

    func retryPendingSync() {
        sentActionIDs.removeAll()
        flushPendingActions()
        requestFreshSnapshot()
    }

    func startMovementSession() {
        guard localState.activeKickStartedAt == nil else { return }
        localState.activeKickStartedAt = Date()
        localState.activeKickCount = 0
        persist()
    }

    func recordMovement() {
        guard localState.activeKickStartedAt != nil else { return }
        localState.activeKickCount += 1
        persist()
    }

    func finishMovementSession() {
        guard let startedAt = localState.activeKickStartedAt else { return }
        let endedAt = Date()
        let count = localState.activeKickCount
        let session = WatchMovementSession(id: UUID(), startedAt: startedAt, endedAt: endedAt, movementCount: count)
        localState.kickHistory.append(session)
        localState.activeKickStartedAt = nil
        localState.activeKickCount = 0
        record(WatchCompanionAction(
            id: session.id, kind: .kickSession, occurredAt: endedAt, dayKey: LocalDay.key(for: endedAt),
            title: "Movement session", detail: "Recorded \(count) movements over \(Int(endedAt.timeIntervalSince(startedAt))) seconds."
        ))
    }

    func startContraction() {
        guard localState.activeContractionStartedAt == nil else { return }
        localState.activeContractionStartedAt = Date()
        persist()
    }

    func stopContraction() {
        guard let startedAt = localState.activeContractionStartedAt else { return }
        let endedAt = Date()
        let interval = localState.previousContractionEnd.map { max(0, Int(startedAt.timeIntervalSince($0))) }
        localState.currentContractions.append(WatchContractionRecord(
            id: UUID(), startedAt: startedAt,
            durationSeconds: max(0, Int(endedAt.timeIntervalSince(startedAt))),
            intervalSeconds: interval
        ))
        localState.previousContractionEnd = endedAt
        localState.activeContractionStartedAt = nil
        persist()
    }

    func finishContractionSession() {
        if localState.activeContractionStartedAt != nil { stopContraction() }
        guard !localState.currentContractions.isEmpty else { return }
        let records = localState.currentContractions
        let sessionSummary = WatchContractionSession(id: UUID(), endedAt: Date(), records: records)
        localState.contractionHistory.append(sessionSummary)
        localState.currentContractions = []
        localState.previousContractionEnd = nil
        let detail = records.enumerated().map { index, item in
            "#\(index + 1) \(item.durationSeconds)s" + (item.intervalSeconds.map { " · interval \($0)s" } ?? "")
        }.joined(separator: ", ")
        record(WatchCompanionAction(
            id: sessionSummary.id, kind: .contractionSession, occurredAt: sessionSummary.endedAt,
            dayKey: LocalDay.key(for: sessionSummary.endedAt), title: "Contraction timing session", detail: detail
        ))
    }

    func setHydrationServing(_ millilitres: Int) {
        localState.hydrationServingML = min(1000, max(50, millilitres))
        persist()
    }

    func setHydrationTarget(_ millilitres: Int?) {
        localState.hydrationTargetML = millilitres.map { min(6000, max(250, $0)) }
        persist()
    }

    func addWater() {
        addWaterAdjustment(localState.hydrationServingML)
    }

    func undoWater() {
        guard waterTodayML > 0,
              let lastServing = localState.actions.last(where: {
                  $0.kind == .hydration && $0.dayKey == LocalDay.key(for: Date()) && ($0.amountMillilitres ?? 0) > 0
              }),
              let previousAmount = lastServing.amountMillilitres else { return }
        addWaterAdjustment(-min(previousAmount, waterTodayML))
    }

    private func addWaterAdjustment(_ amount: Int) {
        let now = Date()
        record(WatchCompanionAction(
            id: UUID(), kind: .hydration, occurredAt: now, dayKey: LocalDay.key(for: now),
            amountMillilitres: amount, title: amount >= 0 ? "Water added" : "Water adjustment",
            detail: "User-recorded water intake; not a prescribed target."
        ))
    }

    func recordDose(_ medication: WatchMedication, status: String) {
        guard !localState.actions.contains(where: {
            $0.kind == .medicationDose && $0.occurrenceID == medication.id
        }) else { return }
        let now = Date()
        record(WatchCompanionAction(
            id: UUID(), kind: .medicationDose, occurredAt: now, dayKey: LocalDay.key(for: now),
            scheduleID: medication.scheduleID, occurrenceID: medication.id, doseStatus: status,
            title: medication.name, detail: "User-reported dose status recorded on Apple Watch."
        ))
    }

    func recordQuickCare(_ kind: WatchActionKind) {
        guard [.feeding, .diaper, .recoveryCheckIn, .sleepSession].contains(kind) else { return }
        let now = Date()
        let label: String
        switch kind {
        case .feeding: label = "Feeding started"
        case .diaper: label = "Diaper changed"
        case .sleepSession: label = "Sleep note"
        default: label = "Recovery check-in"
        }
        record(WatchCompanionAction(
            id: UUID(), kind: kind, occurredAt: now, dayKey: LocalDay.key(for: now),
            title: label, detail: "Quick care note entered on Apple Watch."
        ))
    }

    private func record(_ action: WatchCompanionAction) {
        localState.actions.append(action)
        if localState.actions.count > 500 { localState.actions.removeFirst(localState.actions.count - 500) }
        localState.pendingActionIDs.append(action.id)
        persist()
        flushPendingActions()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(localState) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func flushPendingActions() {
        guard let session, session.activationState == .activated else { return }
        let pending = localState.pendingActionIDs
        for identifier in pending where !sentActionIDs.contains(identifier) {
            guard let action = localState.actions.first(where: { $0.id == identifier }),
                  let data = try? JSONEncoder().encode(action) else { continue }
            session.transferUserInfo(["action": data])
            sentActionIDs.insert(identifier)
        }
        if pending.isEmpty {
            connectionDescription = snapshot == nil ? "Open MamAmie on iPhone to share care details" : "Synced with iPhone"
        } else {
            connectionDescription = "\(pending.count) item\(pending.count == 1 ? "" : "s") waiting to sync"
        }
    }

    private func apply(_ dictionary: [String: Any]) {
        guard let data = dictionary["snapshot"] as? Data,
              let received = try? JSONDecoder().decode(WatchCompanionSnapshot.self, from: data) else { return }
        DispatchQueue.main.async {
            self.snapshot = received
            if !self.localState.pendingActionIDs.isEmpty {
                self.connectionDescription = "\(self.localState.pendingActionIDs.count) item\(self.localState.pendingActionIDs.count == 1 ? "" : "s") waiting to sync"
            } else {
                self.connectionDescription = "Phone details updated \(received.updatedAt.formatted(date: .omitted, time: .shortened))"
            }
        }
    }

    private func acknowledge(_ userInfo: [String: Any]) {
        guard let rawID = userInfo["acknowledgedActionID"] as? String,
              let identifier = UUID(uuidString: rawID) else { return }
        DispatchQueue.main.async {
            self.localState.pendingActionIDs.removeAll { $0 == identifier }
            self.sentActionIDs.remove(identifier)
            self.lastAcknowledgedAt = Date()
            self.persist()
            self.flushPendingActions()
        }
    }
}

extension WatchCompanionStore: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.connectionDescription = "Sync is unavailable right now"
                _ = error
            } else {
                self.apply(session.receivedApplicationContext)
                self.flushPendingActions()
                self.requestFreshSnapshot()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        acknowledge(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        if message["acknowledgedActionID"] != nil { acknowledge(message) }
        replyHandler([:])
    }
}
