import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var lockTime: Date = Date()
    @State private var showActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var isScheduled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Lock Schedule") {
                    DatePicker(
                        "Lock Time",
                        selection: $lockTime,
                        displayedComponents: .hourAndMinute
                    )
                    Button(isScheduled ? "Reschedule Lock" : "Schedule Lock") {
                        scheduleLock()
                    }
                }

                Section("Home Location") {
                    if appState.settings.homeIsSet {
                        LabeledContent("Home Set") {
                            Text(String(format: "%.4f, %.4f",
                                       appState.settings.homeLatitude,
                                       appState.settings.homeLongitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Set Home to Current Location") {
                        setHomeHere()
                    }
                }

                Section("Apps to Block") {
                    Button("Select Apps") {
                        showActivityPicker = true
                    }
                }

                if appState.isHomeSet {
                    Section {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .navigationTitle("Setup")
            .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
            .onChange(of: activitySelection) { _, newValue in
                saveActivitySelection(newValue)
            }
            .onAppear { loadCurrentState() }
        }
    }

    private func loadCurrentState() {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.hour = appState.settings.lockHour
        comps.minute = appState.settings.lockMinute
        if let date = cal.date(from: comps) {
            lockTime = date
        }

        if let data = UserDefaults(suiteName: AppSettings.appGroupID)?.data(forKey: "selectedAppsData"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activitySelection = selection
        }
    }

    private func scheduleLock() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: lockTime)
        let hour = comps.hour ?? 21
        let minute = comps.minute ?? 0

        var updated = appState.settings
        updated.lockHour = hour
        updated.lockMinute = minute
        updated.save()
        appState.settings = updated

        ScheduleManager.shared.scheduleDailyLock(hour: hour, minute: minute)
        isScheduled = true
    }

    private func setHomeHere() {
        // GeofenceManager is owned by the app; we call via a notification so it can use its locationManager
        NotificationCenter.default.post(name: .setHomeHere, object: nil)
    }

    private func saveActivitySelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        UserDefaults(suiteName: AppSettings.appGroupID)?.set(data, forKey: "selectedAppsData")
    }
}

extension Notification.Name {
    static let setHomeHere = Notification.Name("SetHomeHere")
}
