import SwiftUI

struct LockScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var showCamera = false

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

                Text("Take a photo of your medication bottle to unlock your phone.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    showCamera = true
                } label: {
                    Label("Open Camera", systemImage: "camera.fill")
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
        .sheet(isPresented: $showCamera) {
            CameraView()
                .environment(appState)
        }
    }
}
