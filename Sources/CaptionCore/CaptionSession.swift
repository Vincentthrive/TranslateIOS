import AVFoundation
import Foundation

@MainActor
final class CaptionSession: ObservableObject {
    enum State: Equatable {
        case idle
        case listening
        case failed(String)
    }

    struct Caption: Equatable {
        var english = ""
        var chinese = ""
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var caption = Caption()
    @Published private(set) var isTranslating = false
    @Published var errorMessage: String?

    private var processor: TranscriptProcessor
    private let audio: AudioCapturing
    private let speech: SpeechRecognizing
    private let translator: Translating
    private let permissions: PermissionChecking
    private var translationTask: Task<Void, Never>?

    init(
        processor: TranscriptProcessor = TranscriptProcessor(),
        audio: AudioCapturing = AudioCaptureService(),
        speech: SpeechRecognizing = SpeechRecognitionService(),
        translator: Translating = OnDeviceTranslationService(),
        permissions: PermissionChecking = SystemPermissionChecker()
    ) {
        self.processor = processor
        self.audio = audio
        self.speech = speech
        self.translator = translator
        self.permissions = permissions

        self.audio.onBuffer = { [weak self] buffer, _ in
            self?.speech.append(buffer)
        }
        self.speech.onResult = { [weak self] result in
            Task { @MainActor in
                self?.handleSpeechResult(result)
            }
        }
        self.speech.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleSpeechError(error)
            }
        }
    }

    func start() async {
        guard state != .listening else { return }
        guard await permissions.microphoneGranted() else {
            state = .failed("需要麦克风权限才能聆听会议声音")
            errorMessage = "请在系统设置中允许本 App 使用麦克风。"
            return
        }
        guard await permissions.speechGranted() else {
            state = .failed("需要语音识别权限才能生成字幕")
            errorMessage = "请在系统设置中允许本 App 使用语音识别。"
            return
        }
        do {
            try speech.start()
            try audio.start()
            state = .listening
            errorMessage = nil
        } catch {
            state = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        translationTask?.cancel()
        translationTask = nil
        audio.stop()
        speech.stop()
        isTranslating = false
        state = .idle
    }

    func clear() {
        caption = Caption()
        processor.reset()
        isTranslating = false
    }

    func handleSpeechResult(_ result: SpeechRecognitionResult) {
        guard state == .listening else { return }
        caption.english = processor.merge(spoken: result.text, isFinal: result.isFinal)
        scheduleTranslation(result.text)
    }

    private func scheduleTranslation(_ text: String) {
        translationTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isTranslating = true
        translationTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                let translated = try await self?.translator.translate(trimmed) ?? ""
                guard !Task.isCancelled else { return }
                self?.caption.chinese = translated
            } catch is CancellationError {
                // 新文本到达，旧翻译任务被取消，忽略。
            } catch {
                // 保留上一次译文，避免字幕闪空。
            }
            self?.isTranslating = false
        }
    }

    private func handleSpeechError(_ error: SpeechRecognitionError) {
        stop()
        state = .failed(error.localizedDescription)
        errorMessage = error.localizedDescription
    }
}
