import SwiftUI

struct LockScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var showUnlock = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Time for your medication")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Tap your medication tag to unlock your phone.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    showUnlock = true
                } label: {
                    Label("Tap to Unlock", systemImage: "wave.3.right")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
        }
        .sheet(isPresented: $showUnlock) {
            NFCUnlockView()
                .environment(appState)
        }
    }
}
