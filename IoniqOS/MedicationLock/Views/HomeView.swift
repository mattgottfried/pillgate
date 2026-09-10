import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showUnlock = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                statusCard

                if appState.lockStatus == .locked {
                    Button {
                        showUnlock = true
                    } label: {
                        Label("Tap to Unlock", systemImage: "wave.3.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("PillGate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showUnlock) {
                NFCUnlockView()
                    .environment(appState)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(appState)
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 60))
                .foregroundStyle(statusColor)

            Text(statusTitle)
                .font(.title2.bold())

            Text(statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusIcon: String {
        switch appState.lockStatus {
        case .unlocked: return "lock.open.fill"
        case .locked: return "lock.fill"
        case .pendingHomeArrival: return "clock.fill"
        }
    }

    private var statusColor: Color {
        switch appState.lockStatus {
        case .unlocked: return .green
        case .locked: return .red
        case .pendingHomeArrival: return .orange
        }
    }

    private var statusTitle: String {
        switch appState.lockStatus {
        case .unlocked: return "Unlocked"
        case .locked: return "Locked"
        case .pendingHomeArrival: return "Pending"
        }
    }

    private var statusDescription: String {
        switch appState.lockStatus {
        case .unlocked: return "Your apps are accessible. Lock will apply at the scheduled time."
        case .locked: return "Apps are shielded. Tap your medication tag to unlock."
        case .pendingHomeArrival: return "Lock will apply when you arrive home."
        }
    }
}
