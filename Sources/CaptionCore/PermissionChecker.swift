import AVFoundation
import Foundation
import Speech

protocol PermissionChecking {
    func microphoneGranted() async -> Bool
    func speechGranted() async -> Bool
}

struct SystemPermissionChecker: PermissionChecking {
    func microphoneGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func speechGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
