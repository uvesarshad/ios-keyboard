import Foundation

enum AppGroup {
    static let identifier = "group.com.uves.tactl"
    static let defaults = UserDefaults(suiteName: identifier)!
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)!
    }
}
