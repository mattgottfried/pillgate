import Foundation
import ManagedSettings
import FamilyControls

final class LockManager {
    static let shared = LockManager()
    private let store = ManagedSettingsStore()
    private let appGroupID = "group.com.mattgottfried.medlock"
    private var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    func applyLock() {
        guard let data = defaults?.data(forKey: "selectedAppsData"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        store.shield.applications = selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        defaults?.set(LockStatus.locked.rawValue, forKey: "lockStatus")
        defaults?.set(false, forKey: "lockPending")
    }

    func unlock() {
        store.clearAllSettings()
        defaults?.set(LockStatus.unlocked.rawValue, forKey: "lockStatus")
        defaults?.set(false, forKey: "lockPending")
    }
}
