import AVFoundation
import XCTest
@testable import CaptionSubtitle

final class TranslationServiceTests: XCTestCase {
    func testMockTranslatorReturnsExpectedText() async throws {
        let translator = MockTranslating(result: "你好")
        let text = try await translator.translate("Hello")
        XCTAssertEqual(text, "你好")
    }
}

@MainActor
final class CaptionSessionTests: XCTestCase {
    func testStartListensAfterPermissionsGranted() async {
        let session = makeSession()
        await session.start()
        XCTAssertEqual(session.state, .listening)
    }

    func testTranslationUpdatesChinese() async throws {
        let speech = MockSpeech()
        let session = makeSession(speech: speech)
        await session.start()
        speech.emit(.init(text: "Hello", isFinal: true))
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(session.caption.english, "Hello")
        XCTAssertEqual(session.caption.chinese, "你好")
    }

    func testStopReturnsToIdle() async {
        let session = makeSession()
        await session.start()
        session.stop()
        XCTAssertEqual(session.state, .idle)
    }

    func testDeniedMicrophoneShowsFailure() async {
        let session = makeSession(permissions: DeniedMicrophonePermissions())
        await session.start()
        XCTAssertEqual(session.state, .failed("需要麦克风权限才能聆听会议声音"))
    }

    private func makeSession(
        speech: MockSpeech = MockSpeech(),
        permissions: PermissionChecking = AlwaysGrantedPermissions()
    ) -> CaptionSession {
        CaptionSession(
            audio: MockAudio(),
            speech: speech,
            translator: MockTranslating(result: "你好"),
            permissions: permissions
        )
    }
}

private final class MockAudio: AudioCapturing {
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    private(set) var started = false
    func start() throws { started = true }
    func stop() { started = false }
}

private final class MockSpeech: SpeechRecognizing {
    var onResult: ((SpeechRecognitionResult) -> Void)?
    var onError: ((SpeechRecognitionError) -> Void)?
    private(set) var started = false
    func start() throws { started = true }
    func append(_ buffer: AVAudioPCMBuffer) {}
    func stop() { started = false }
    func emit(_ result: SpeechRecognitionResult) {
        onResult?(result)
    }
}

private struct MockTranslating: Translating {
    let result: String
    func translate(_ text: String) async throws -> String {
        result
    }
}

private struct AlwaysGrantedPermissions: PermissionChecking {
    func microphoneGranted() async -> Bool { true }
    func speechGranted() async -> Bool { true }
}

private struct DeniedMicrophonePermissions: PermissionChecking {
    func microphoneGranted() async -> Bool { false }
    func speechGranted() async -> Bool { true }
}
