import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth
import Combine

final class StaminaService: ObservableObject {
    static let shared = StaminaService()

    @Published private(set) var current: Int = 0
    @Published private(set) var max: Int = 4
    @Published private(set) var nextRefillAt: Date?
    @Published private(set) var isLoading: Bool = false

    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast1")
    private var listener: ListenerRegistration?
    private var autoRefillTimer: Timer?
    private var activeUid: String?
    private var loadingTaskCount: Int = 0

    private func beginLoading() async {
        await MainActor.run {
            loadingTaskCount += 1
            isLoading = true
        }
    }

    private func endLoading() async {
        await MainActor.run {
            loadingTaskCount = Swift.max(loadingTaskCount - 1, 0)
            isLoading = loadingTaskCount > 0
        }
    }

    func start(uid: String) {
        listener?.remove()
        autoRefillTimer?.invalidate(); autoRefillTimer = nil
        activeUid = uid
        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let data = snap?.data(),
                      let stamina = data["stamina"] as? [String: Any] else { return }
                let cur = stamina["current"] as? Int ?? 0
                let mx = stamina["max"] as? Int ?? 4
                DispatchQueue.main.async {
                    self?.current = cur
                    self?.max = mx
                }
            }
        DispatchQueue.main.async { [weak self] in
            self?.scheduleAutoRefillTimerUsingStoredDate()
        }
        Task { [weak self] in
            do {
                _ = try await self?.checkAndRefillIfReady()
            } catch {
            }
        }
    }

    func stop() {
        listener?.remove(); listener = nil
        autoRefillTimer?.invalidate(); autoRefillTimer = nil
        activeUid = nil
    }

    func ensureDefaults() async {
        await beginLoading()
        do { _ = try await functions.httpsCallable("ensureStaminaDefaults").call([:]) } catch { }
        await endLoading()
    }

    @discardableResult
    func consumeForLike() async throws -> (current: Int, max: Int) {
        await beginLoading()
        do {
            let res = try await functions.httpsCallable("likeConsumeStamina").call([:])
            guard let dict = res.data as? [String: Any],
                  let cur = dict["current"] as? Int,
                  let mx = dict["max"] as? Int else { throw NSError(domain: "Stamina", code: -1) }
            let nextMs = dict["nextRefillAt"] as? Double
            DispatchQueue.main.async { [weak self] in
                self?.applyServerUpdate(current: cur, max: mx, nextRefillMs: nextMs)
            }
            await endLoading()
            return (cur, mx)
        } catch {
            await endLoading()
            throw error
        }
    }

    @discardableResult
    func checkAndRefillIfReady() async throws -> (didRefill: Bool, current: Int, max: Int) {
        await beginLoading()
        do {
            let res = try await functions.httpsCallable("checkAndRefillStamina").call([:])
            guard let dict = res.data as? [String: Any],
                  let cur = dict["current"] as? Int,
                  let mx = dict["max"] as? Int,
                  let did = dict["didRefill"] as? Bool else { throw NSError(domain: "Stamina", code: -2) }
            let nextMs = dict["nextRefillAt"] as? Double
            DispatchQueue.main.async { [weak self] in
                self?.applyServerUpdate(current: cur, max: mx, nextRefillMs: nextMs)
            }
            await endLoading()
            return (did, cur, mx)
        } catch {
            await endLoading()
            throw error
        }
    }

    private func applyServerUpdate(current: Int, max: Int, nextRefillMs: Double?) {
        self.current = current
        self.max = max
        if let ms = nextRefillMs {
            self.nextRefillAt = Date(timeIntervalSince1970: ms / 1000)
        } else if nextRefillAt == nil {
            self.nextRefillAt = defaultNextRefillDate(after: Date())
        }
        scheduleAutoRefillTimerUsingStoredDate()
    }

    @discardableResult
    func recoverOneFromAd() async throws -> (didRecover: Bool, current: Int, max: Int) {
        await beginLoading()
        do {
            let res = try await functions.httpsCallable("recoverStaminaWithAd").call([:])
            guard let dict = res.data as? [String: Any],
                  let cur = dict["current"] as? Int,
                  let mx = dict["max"] as? Int,
                  let did = dict["didRecover"] as? Bool else { throw NSError(domain: "Stamina", code: -3) }
            let nextMs = dict["nextRefillAt"] as? Double
            DispatchQueue.main.async { [weak self] in
                self?.applyServerUpdate(current: cur, max: mx, nextRefillMs: nextMs)
            }
            await endLoading()
            return (did, cur, mx)
        } catch {
            await endLoading()
            throw error
        }
    }

    private func defaultNextRefillDate(after referenceDate: Date) -> Date {
        let hours = [4, 10, 16, 22]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? calendar.timeZone
        let base = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        for hour in hours {
            var components = base
            components.hour = hour
            components.minute = 0
            components.second = 0
            if let candidate = calendar.date(from: components), candidate > referenceDate {
                return candidate
            }
        }
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate)) else {
            return referenceDate
        }
        var nextComponents = calendar.dateComponents([.year, .month, .day], from: startOfNextDay)
        nextComponents.hour = hours.first
        nextComponents.minute = 0
        nextComponents.second = 0
        return calendar.date(from: nextComponents) ?? referenceDate
    }

    private func scheduleAutoRefillTimerUsingStoredDate() {
        autoRefillTimer?.invalidate(); autoRefillTimer = nil
        guard activeUid != nil else { return }
        let reference = Date()
        let target = (nextRefillAt ?? defaultNextRefillDate(after: reference))
        let interval = target.timeIntervalSince(reference)
        if interval <= 1 {
            DispatchQueue.main.async { [weak self] in self?.handleAutoRefillTimerFired() }
            return
        }
        let timer = Timer(fire: target, interval: 0, repeats: false) { [weak self] _ in
            self?.handleAutoRefillTimerFired()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefillTimer = timer
    }

    private func scheduleAutoRefillRetry(after interval: TimeInterval) {
        autoRefillTimer?.invalidate(); autoRefillTimer = nil
        guard activeUid != nil else { return }
        let timer = Timer(fire: Date().addingTimeInterval(interval), interval: 0, repeats: false) { [weak self] _ in
            self?.handleAutoRefillTimerFired()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefillTimer = timer
    }

    private func handleAutoRefillTimerFired() {
        guard activeUid != nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.checkAndRefillIfReady()
            } catch {
                await MainActor.run {
                    self.scheduleAutoRefillRetry(after: 300)
                }
            }
        }
    }
}
