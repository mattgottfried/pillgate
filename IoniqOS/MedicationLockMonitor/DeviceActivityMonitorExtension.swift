import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let appGroupID = "group.com.mattgottfried.medlock"
    private var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let isAtHome = defaults?.bool(forKey: "isAtHome") ?? false
        if isAtHome {
            applyShields()
        } else {
            defaults?.set(true, forKey: "lockPending")
            defaults?.set("pendingHomeArrival", forKey: "lockStatus")
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Interval ends at 23:59 — shields remain until user unlocks via camera
    }

    private func applyShields() {
        guard let data = defaults?.data(forKey: "selectedAppsData"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }

        let store = ManagedSettingsStore()
        store.shield.applications = selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
        defaults?.set("locked", forKey: "lockStatus")
    }
}
