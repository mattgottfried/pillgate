import Foundation
import DeviceActivity

extension DeviceActivityName {
    static let daily = Self("daily")
}

final class ScheduleManager {
    static let shared = ScheduleManager()

    func scheduleDailyLock(hour: Int, minute: Int) {
        let center = DeviceActivityCenter()
        center.stopMonitoring()

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: hour, minute: minute),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.daily, during: schedule)
        } catch {
            print("Failed to schedule device activity: \(error)")
        }
    }

    func cancelSchedule() {
        DeviceActivityCenter().stopMonitoring()
    }
}
