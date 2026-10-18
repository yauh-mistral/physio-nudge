import Foundation

/// Computes the next fire date for every enabled nudge and presents
/// profiles in a queue (alphabetical order on simultaneous fires, FR-03).
/// Pure logic — no AppKit — so it is unit-testable.
final class NudgeScheduler {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func nextFireDates(nudges: [Nudge], after now: Date = Date()) -> [(nudge: Nudge, fireDate: Date)] {
        nudges
            .filter { $0.enabled }
            .compactMap { nudge -> (Nudge, Date)? in
                guard let fire = nudge.schedule.nextFire(after: now, calendar: calendar) else {
                    return nil
                }
                return (nudge, fire)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
                return lhs.0.profileId < rhs.0.profileId
            }
    }
}

/// Ordered queue of profiles waiting to be presented; only one overlay at
/// a time (NFR-11), simultaneous nudges run sequentially (FR-03).
final class PresentationQueue {
    private var pending: [Nudge] = []

    var isEmpty: Bool { pending.isEmpty }

    func enqueue(_ nudge: Nudge) {
        pending.append(nudge)
    }

    /// Alphabetical by profile id (FR-03), stable for same profile.
    func dequeueNext() -> Nudge? {
        guard !pending.isEmpty else { return nil }
        pending.sort { $0.profileId < $1.profileId }
        return pending.removeFirst()
    }

    func clear() {
        pending.removeAll()
    }
}

import AppKit

/// Owns the single timed event, recalibrates on sleep/wake (NFR-10), and
/// drives overlay presentation through the queue.
final class SchedulerService {
    private let store: DataStore
    private let scheduler = NudgeScheduler()
    private let queue = PresentationQueue()
    private var timer: Timer?
    private var isPresenting = false

    /// Called by the service when a profile should be shown in the overlay.
    var onPresent: ((Profile) -> Void)?

    init(store: DataStore = .shared) {
        self.store = store
    }

    func start() {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.reschedule() }
        }
        reschedule()
    }

    /// Presents the first enabled nudge immediately (manual trigger).
    func triggerNow() {
        guard let nudge = store.nudges.first(where: { $0.enabled }) else { return }
        fire(nudge: nudge)
    }

    func reschedule() {
        timer?.invalidate()
        let pairs = scheduler.nextFireDates(nudges: store.nudges)
        guard let next = pairs.first else {
            timer = nil
            return
        }
        let interval = max(1, next.fireDate.timeIntervalSinceNow)
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        print("[PhysioNudge] scheduler: next '\(next.nudge.name)' at \(formatter.string(from: next.fireDate)) (in \(Int(interval)) s)")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("[PhysioNudge] scheduler: firing '\(next.nudge.name)'")
                self?.fire(nudge: next.nudge)
                self?.reschedule()
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func fire(nudge: Nudge) {
        guard let profile = store.library.profile(id: nudge.profileId),
              !profile.entries.isEmpty else {
            print("[PhysioNudge] scheduler: nudge '\(nudge.name)' has no usable profile — skipped")
            return
        }
        queue.enqueue(nudge)
        presentNextIfIdle()
    }

    private func presentNextIfIdle() {
        guard !isPresenting else { return }
        presentNext()
    }

    private func presentNext() {
        guard let nudge = queue.dequeueNext() else {
            isPresenting = false
            return
        }
        guard let profile = store.library.profile(id: nudge.profileId),
              !profile.entries.isEmpty else {
            presentNext()
            return
        }
        isPresenting = true
        onPresent?(profile)
    }

    /// Called by the UI when the current overlay finished/dismissed.
    func overlayDidFinish() {
        isPresenting = false
        presentNext()
    }
}
