import Foundation

enum PersonalDictionary {
    private static let filename = "personal_dictionary.json"

    private static var fileURL: URL {
        AppGroup.containerURL.appendingPathComponent(filename)
    }

    static func load() -> [String] {
        guard let data = try? Data(contentsOf: fileURL),
              let words = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return words
    }

    static func save(_ words: [String]) {
        let unique = Array(Set(words)).sorted()
        guard let data = try? JSONEncoder().encode(unique) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    @discardableResult
    static func add(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        var words = load()
        guard !words.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return false
        }
        words.append(trimmed)
        save(words)
        return true
    }

    static func remove(_ word: String) {
        let words = load().filter { $0.caseInsensitiveCompare(word) != .orderedSame }
        save(words)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
