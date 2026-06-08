import Foundation
import Observation

enum LockStatus: String {
    case unlocked
    case pendingHomeArrival
    case locked
}

@Observable
final class AppState {
    static let appGroupID = "group.com.mattgottfried.ioniqos"

    var lockStatus: LockStatus = .unlocked
    var settings: AppSettings = AppSettings()
    var isAuthorized: Bool = false

    private var defaults: UserDefaults? { UserDefaults(suiteName: AppState.appGroupID) }

    init() {
        loadFromDefaults()
    }

    func loadFromDefaults() {
        settings = AppSettings.load()
        if let raw = defaults?.string(forKey: "lockStatus"),
           let status = LockStatus(rawValue: raw) {
            lockStatus = status
        }
    }

    func setLockStatus(_ status: LockStatus) {
        lockStatus = status
        defaults?.set(status.rawValue, forKey: "lockStatus")
    }

    var isHomeSet: Bool { settings.homeIsSet }
}
