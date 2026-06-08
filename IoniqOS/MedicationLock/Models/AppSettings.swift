import Foundation
import CoreLocation

struct AppSettings: Codable {
    var lockHour: Int = 21
    var lockMinute: Int = 0
    var homeLatitude: Double = 0.0
    var homeLongitude: Double = 0.0
    var homeIsSet: Bool = false

    static let appGroupID = "group.com.mattgottfried.ioniqos"

    static func load() -> AppSettings {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "appSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: AppSettings.appGroupID),
              let data = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(data, forKey: "appSettings")
    }
}
