import SwiftUI

struct NFCUnlockView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var nfcManager = NFCManager()
    @State private var isScanning = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: showSuccess ? "checkmark.circle.fill" : "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(showSuccess ? .green : .blue)

            if showSuccess {
                Text("Medication confirmed!")
                    .font(.title2.bold())
            } else {
                Text("Tap Your Medication Tag")
                    .font(.title2.bold())
                Text("Hold the top of your iPhone near the NFC tag on your medication bottle.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(isScanning ? "Scanning…" : "Scan Tag", action: scan)
                    .buttonStyle(.borderedProminent)
                    .disabled(isScanning)
            }

            Spacer()

            if !showSuccess {
                Button("Cancel") { dismiss() }
                    .padding(.bottom, 20)
            }
        }
        .padding()
    }

    private func scan() {
        guard let expectedUID = appState.settings.registeredTagUID else {
            errorMessage = "No medication tag registered. Set one up in Settings."
            return
        }
        isScanning = true
        errorMessage = nil
        nfcManager.verifyTag(expectedUID: expectedUID) { result in
            isScanning = false
            switch result {
            case .success(true):
                showSuccess = true
                LockManager.shared.unlock()
                appState.setLockStatus(.unlocked)
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            case .success(false):
                errorMessage = "That's not your medication tag. Try again."
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
