import AppKit

struct Exercise: Codable {
    let title: String
    let caption: String
    let gifs: [String]
}

struct Catalog: Codable {
    var perGifSeconds: Double?
    var exercises: [Exercise]
}

/// Lädt exercises.json und die GIF-Dateien gemäß requirements/06:
/// 1. ~/Library/Application Support/PhysioNudge/Exercises (Nutzer, hat Vorrang)
/// 2. App-Bundle Contents/Resources/Exercises (mitgeliefert)
final class ExerciseCatalog {
    private(set) var catalog = Catalog(perGifSeconds: nil, exercises: [])
    private(set) var exerciseDirectory: URL

    init() {
        let candidates: [URL] = [
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first?.appendingPathComponent("PhysioNudge/Exercises"),
            Bundle.main.resourceURL?.appendingPathComponent("Exercises"),
        ].compactMap { $0 }

        exerciseDirectory = candidates.first { directory in
            FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("exercises.json").path)
        } ?? candidates[0]

        guard let data = try? Data(contentsOf: exerciseDirectory.appendingPathComponent("exercises.json")),
              let decoded = try? JSONDecoder().decode(Catalog.self, from: data) else {
            return
        }
        catalog = decoded
    }

    /// FR-10: nur Übungen, deren GIF-Dateien auch tatsächlich existieren.
    var availableExercises: [Exercise] {
        catalog.exercises.filter { exercise in
            !exercise.gifs.isEmpty && exercise.gifs.allSatisfy { name in
                FileManager.default.fileExists(
                    atPath: exerciseDirectory.appendingPathComponent(name).path)
            }
        }
    }

    func randomExercise() -> Exercise? {
        availableExercises.randomElement()
    }
}
