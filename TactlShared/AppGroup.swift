import Foundation

enum AppGroup {
    static let identifier = "group.com.uves.tactl"

    // Safe fallback to standard defaults if App Group isn't provisioned yet
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.temporaryDirectory
    }
}
