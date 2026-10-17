import Foundation

struct Exercise: Codable {
    var id: String
    var title: String
}

/// One step inside a profile: an exercise plus its amount (reps) or time.
struct ProfileEntry: Codable {
    var exerciseId: String
    var reps: Int?
    var seconds: Int?
}

struct Profile: Codable {
    var id: String
    var name: String
    var entries: [ProfileEntry]
}

struct ExerciseLibrary: Codable {
    var exercises: [Exercise]
    var profiles: [Profile]

    func exercise(id: String) -> Exercise? {
        exercises.first { $0.id == id }
    }

    func profile(id: String) -> Profile? {
        profiles.first { $0.id == id }
    }
}

struct Schedule: Codable {
    var type: String
    var intervalMinutes: Int?
    var fromTime: String?
    var toTime: String?
    var times: [String]?

    func summary() -> String {
        switch type {
        case "interval":
            return "Every \(intervalMinutes ?? 60) min"
        case "hourly":
            return "Hourly \(fromTime ?? "?")–\(toTime ?? "?")"
        case "at":
            return "At \((times ?? []).joined(separator: ", "))"
        default:
            return type
        }
    }

    func nextFire(after now: Date, calendar: Calendar) -> Date? {
        switch type {
        case "interval":
            let minutes = max(1, intervalMinutes ?? 60)
            return now.addingTimeInterval(TimeInterval(minutes * 60))
        case "hourly":
            let comps = calendar.dateComponents([.year, .month, .day], from: now)
            guard let from = Self.hourMinute(fromTime),
                  let to = Self.hourMinute(toTime) else { return nil }
            var candidates: [Date] = []
            var hour = from.hour
            while hour <= to.hour {
                var c = comps
                c.hour = hour
                c.minute = from.minute
                if let d = calendar.date(from: c), d > now {
                    candidates.append(d)
                }
                hour += 1
            }
            if let next = candidates.first { return next }
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            let tomorrowComps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            var c = tomorrowComps
            c.hour = from.hour
            c.minute = from.minute
            return calendar.date(from: c)
        case "at":
            let times = (self.times ?? []).compactMap { Self.hourMinute($0) }
            guard !times.isEmpty else { return nil }
            let comps = calendar.dateComponents([.year, .month, .day], from: now)
            var candidates: [Date] = []
            for t in times {
                var c = comps
                c.hour = t.hour
                c.minute = t.minute
                if let d = calendar.date(from: c), d > now {
                    candidates.append(d)
                }
            }
            if let next = candidates.min() { return next }
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            let tomorrowComps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            var tomorrowCandidates: [Date] = []
            for t in times {
                var c = tomorrowComps
                c.hour = t.hour
                c.minute = t.minute
                if let d = calendar.date(from: c) {
                    tomorrowCandidates.append(d)
                }
            }
            return tomorrowCandidates.min()
        default:
            return nil
        }
    }

    static func hourMinute(_ string: String?) -> (hour: Int, minute: Int)? {
        guard let string = string else { return nil }
        let parts = string.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]),
              (0...23).contains(h), (0...59).contains(m) else { return nil }
        return (h, m)
    }
}

struct Nudge: Codable {
    var id: String
    var name: String
    var profileId: String
    var schedule: Schedule
    var enabled: Bool
}

struct AppSettings: Codable {
    var corner: String
}

/// One resolved playback item for the overlay: exercise title + amount.
struct OverlayItem {
    let title: String
    let reps: Int?
    let seconds: Int?
}

/// Loads and stores all app data as plain JSON in one Application Support
/// folder (requirements/06, NFR-16: clean uninstall = delete one folder).
final class DataStore {
    static let shared = DataStore()

    let directory: URL
    private(set) var library: ExerciseLibrary
    private(set) var nudges: [Nudge]
    private(set) var settings: AppSettings

    private let libraryURL: URL
    private let nudgesURL: URL
    private let settingsURL: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        directory = support.appendingPathComponent("PhysioNudge", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
        libraryURL = directory.appendingPathComponent("library.json")
        nudgesURL = directory.appendingPathComponent("nudges.json")
        settingsURL = directory.appendingPathComponent("settings.json")

        library = Self.load(libraryURL) ?? Self.seedLibrary()
        if library.exercises.isEmpty && library.profiles.isEmpty {
            library = Self.seedLibrary()
        }
        nudges = Self.load(nudgesURL) ?? Self.seedNudges()
        settings = Self.load(settingsURL) ?? Self.seedSettings()
        persistLibrary()
        persistNudges()
        persistSettings()
    }

    private static func load<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Seeds

    private static func seedLibrary() -> ExerciseLibrary {
        ExerciseLibrary(
            exercises: [
                Exercise(id: "head-nod", title: "Head Nod"),
                Exercise(id: "head-shake", title: "Head Shake"),
                Exercise(id: "ear-to-shoulder", title: "Ear to Shoulder")
            ],
            profiles: [
                Profile(id: "cervical-mobility", name: "Cervical Mobility", entries: [
                    ProfileEntry(exerciseId: "head-nod", reps: 10, seconds: nil),
                    ProfileEntry(exerciseId: "head-shake", reps: 10, seconds: nil),
                    ProfileEntry(exerciseId: "ear-to-shoulder", reps: 10, seconds: nil)
                ])
            ])
    }

    private static func seedNudges() -> [Nudge] {
        [
            Nudge(id: "hourly-cervical", name: "Hourly Cervical Mobility",
                  profileId: "cervical-mobility",
                  schedule: Schedule(type: "interval", intervalMinutes: 60,
                                     fromTime: nil, toTime: nil, times: nil),
                  enabled: true)
        ]
    }

    private static func seedSettings() -> AppSettings {
        AppSettings(corner: "bottomRight")
    }

    // MARK: - Library mutation

    func add(exercise: Exercise) {
        library.exercises.append(exercise)
        persistLibrary()
    }

    func add(profile: Profile) {
        library.profiles.append(profile)
        persistLibrary()
    }

    func update(profile: Profile) {
        if let index = library.profiles.firstIndex(where: { $0.id == profile.id }) {
            library.profiles[index] = profile
        } else {
            library.profiles.append(profile)
        }
        persistLibrary()
    }

    // MARK: - Nudges / settings mutation

    func persistLibrary() { Self.save(library, to: libraryURL) }
    func persistNudges() { Self.save(nudges, to: nudgesURL) }
    func persistSettings() { Self.save(settings, to: settingsURL) }

    func update(corner: OverlayCorner) {
        settings.corner = corner.storageKey
        persistSettings()
    }

    func update(nudges newNudges: [Nudge]) {
        nudges = newNudges
        persistNudges()
    }

    var currentCorner: OverlayCorner {
        OverlayCorner.allCases.first { $0.storageKey == settings.corner } ?? .bottomRight
    }
}
