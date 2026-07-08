import SwiftUI
import FamilyControls

@main
struct MedicationLockApp: App {
    @State private var appState = AppState()
    @State private var geofenceManager: GeofenceManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    requestFamilyControlsAuthorization()
                    let gm = GeofenceManager(appState: appState)
                    geofenceManager = gm
                    gm.startIfAuthorized()
                    NotificationCenter.default.addObserver(
                        forName: .setHomeHere,
                        object: nil,
                        queue: .main
                    ) { _ in gm.setupHomeGeofence() }
                }
                .onOpenURL { url in
                    // Handle pillgate://unlock deep link from shield button
                    if url.scheme == "pillgate", url.host == "unlock" {
                        // App is already open; ContentView will show camera flow
                    }
                }
        }
    }

    private func requestFamilyControlsAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run { appState.isAuthorized = true }
            } catch {
                print("Family Controls authorization failed: \(error)")
            }
        }
    }
}
