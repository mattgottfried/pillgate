import CoreNFC

enum NFCUnlockError: LocalizedError {
    case unavailable
    case tagUnreadable

    var errorDescription: String? {
        switch self {
        case .unavailable: return "NFC is not available on this device."
        case .tagUnreadable: return "Could not read that tag. Try again."
        }
    }
}

@Observable
final class NFCManager: NSObject {
    private var completion: ((Result<String, Error>) -> Void)?
    private var session: NFCTagReaderSession?

    func registerTag(completion: @escaping (Result<String, Error>) -> Void) {
        start(alertMessage: "Hold your iPhone near the tag to register it.", completion: completion)
    }

    func verifyTag(expectedUID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        start(alertMessage: "Hold your iPhone near your medication tag to unlock.") { result in
            switch result {
            case .success(let uid): completion(.success(uid == expectedUID))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    private func start(alertMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            completion(.failure(NFCUnlockError.unavailable))
            return
        }
        self.completion = completion
        let session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: nil)
        session?.alertMessage = alertMessage
        self.session = session
        session?.begin()
    }

    private func finish(_ result: Result<String, Error>) {
        DispatchQueue.main.async { [weak self] in
            self?.completion?(result)
            self?.completion = nil
        }
    }
}

extension NFCManager: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            return
        }
        finish(.failure(error))
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if error != nil {
                session.invalidate(errorMessage: "Connection failed.")
                self.finish(.failure(NFCUnlockError.tagUnreadable))
                return
            }

            guard let uid = Self.identifier(for: tag) else {
                session.invalidate(errorMessage: "Could not read tag ID.")
                self.finish(.failure(NFCUnlockError.tagUnreadable))
                return
            }

            session.alertMessage = "Tag recognized!"
            session.invalidate()
            self.finish(.success(uid))
        }
    }

    private static func identifier(for tag: NFCTag) -> String? {
        let data: Data?
        switch tag {
        case .miFare(let t): data = t.identifier
        case .iso15693(let t): data = t.identifier
        case .feliCa(let t): data = t.currentIDm
        case .iso7816(let t): data = t.identifier
        @unknown default: data = nil
        }
        return data?.map { String(format: "%02X", $0) }.joined()
    }
}
