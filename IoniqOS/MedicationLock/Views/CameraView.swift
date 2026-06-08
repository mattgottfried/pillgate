import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var captureSession = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var didCapture = false
    @State private var showSuccess = false
    @State private var cameraError: String?

    var body: some View {
        ZStack {
            if let error = cameraError {
                VStack {
                    Text("Camera unavailable")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                CameraPreview(session: captureSession)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()

                if showSuccess {
                    Text("Medication confirmed!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.green.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 40)
                } else {
                    Button(action: takePhoto) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 4).frame(width: 84, height: 84))
                    }
                    .padding(.bottom, 40)
                }
            }

            VStack {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear { startCamera() }
        .onDisappear { captureSession.stopRunning() }
    }

    private func startCamera() {
        Task.detached {
            do {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                else { throw NSError(domain: "CameraView", code: 1, userInfo: [NSLocalizedDescriptionKey: "No rear camera found"]) }

                let input = try AVCaptureDeviceInput(device: device)
                let session = AVCaptureSession()
                session.sessionPreset = .photo

                guard session.canAddInput(input) else { throw NSError(domain: "CameraView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"]) }
                session.addInput(input)

                let output = AVCapturePhotoOutput()
                guard session.canAddOutput(output) else { throw NSError(domain: "CameraView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot add photo output"]) }
                session.addOutput(output)

                await MainActor.run {
                    self.captureSession = session
                    self.photoOutput = output
                }

                session.startRunning()
            } catch {
                await MainActor.run {
                    self.cameraError = error.localizedDescription
                }
            }
        }
    }

    private func takePhoto() {
        guard !didCapture else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoDelegate { [self] in
            didCapture = true
            showSuccess = true
            LockManager.shared.unlock()
            appState.setLockStatus(.unlocked)
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run { dismiss() }
            }
        })
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Photo Delegate

final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil else { return }
        DispatchQueue.main.async { self.completion() }
    }
}
