import AVFoundation
import Foundation
import Speech

struct SpeechRecognitionResult {
    let text: String
    let isFinal: Bool
}

enum SpeechRecognitionError: LocalizedError {
    case unavailable
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "当前设备不支持英文语音识别。"
        case .recognitionFailed:
            return "语音识别失败，请重新开始。"
        }
    }
}

protocol SpeechRecognizing: AnyObject {
    var onResult: ((SpeechRecognitionResult) -> Void)? { get set }
    var onError: ((SpeechRecognitionError) -> Void)? { get set }
    func start() throws
    func append(_ buffer: AVAudioPCMBuffer)
    func stop()
}

final class SpeechRecognitionService: SpeechRecognizing {
    var onResult: ((SpeechRecognitionResult) -> Void)?
    var onError: ((SpeechRecognitionError) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() throws {
        guard let recognizer, recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            throw SpeechRecognitionError.unavailable
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                self?.onResult?(SpeechRecognitionResult(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal
                ))
            }
            if error != nil {
                self?.onError?(.recognitionFailed)
            }
        }
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func stop() {
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
    }
}
