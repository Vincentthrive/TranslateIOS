# Caption Subtitle 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 iPadOS 17.4+ 应用，通过麦克风实时聆听英文会议声音，在本机识别英文并翻译成中文，以“底部通栏大字幕”界面显示。

**Architecture:** SwiftUI 应用拆分为 AudioCaptureService（麦克风）、SpeechRecognitionService（英文识别）、TranslationService（英中翻译）、TranscriptProcessor（文本合并/节流）、CaptionSession（状态机与数据流）和 CaptionView（界面）。全部 Apple 原生、离线、无后端。

**Tech Stack:** Swift 5.9、SwiftUI、AVFAudio、Speech、Translation、XcodeGen、GitHub Actions（macOS 云端构建）、Sideloadly（Windows 免费签名安装）。

---

## 文件结构

```
iostranslate/
├── project.yml
├── README.md
├── .github/workflows/build-ipa.yml
├── Sources/
│   ├── CaptionApp/
│   │   ├── CaptionApp.swift
│   │   └── ContentView.swift
│   ├── CaptionCore/
│   │   ├── TranscriptProcessor.swift
│   │   ├── AudioCaptureService.swift
│   │   ├── SpeechRecognitionService.swift
│   │   ├── TranslationService.swift
│   │   ├── PermissionChecker.swift
│   │   └── CaptionSession.swift
│   └── CaptionUI/
│       ├── SettingsStore.swift
│       ├── CaptionView.swift
│       └── ControlsView.swift
└── Tests/
    └── CaptionCoreTests/
        ├── TranscriptProcessorTests.swift
        └── CaptionSessionTests.swift
```

## Task 1: XcodeGen 工程骨架

**Files:**
- Create: `project.yml`
- Create: `Sources/CaptionApp/CaptionApp.swift`
- Create: `Sources/CaptionApp/ContentView.swift`
- Create: `README.md`

- [ ] **Step 1: 创建 project.yml**

```yaml
name: CaptionSubtitle
options:
  bundleIdPrefix: com.vincent
  deploymentTarget:
    iOS: "17.4"
  createIntermediateGroups: true
targets:
  CaptionSubtitle:
    type: application
    platform: iOS
    sources:
      - Sources/CaptionApp
      - Sources/CaptionCore
      - Sources/CaptionUI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vincent.CaptionSubtitle
        PRODUCT_NAME: CaptionSubtitle
        INFOPLIST_KEY_CFBundleDisplayName: 会议字幕
        INFOPLIST_KEY_NSMicrophoneUsageDescription: 用于聆听会议声音并生成中文字幕。
        INFOPLIST_KEY_NSSpeechRecognitionUsageDescription: 用于实时识别英文语音并翻译成中文。
        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        TARGETED_DEVICE_FAMILY: "2"
        SWIFT_VERSION: "5.9"
        GENERATE_INFOPLIST_FILE: YES
        CODE_SIGN_STYLE: Automatic
  CaptionCoreTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - Tests/CaptionCoreTests
    dependencies:
      - target: CaptionSubtitle
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "5.9"
schemes:
  CaptionSubtitle:
    build:
      targets:
        CaptionSubtitle: all
    test:
      targets:
        - CaptionCoreTests
```

- [ ] **Step 2: 创建 App 入口**

```swift
import SwiftUI

@main
struct CaptionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 3: 创建临时 ContentView（后续任务替换）**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("会议字幕")
    }
}
```

- [ ] **Step 4: 创建 README 骨架**

```markdown
# 会议字幕

iPad 应用：分屏参加 Zoom 英文会议时，通过麦克风聆听扬声器声音，实时显示中文翻译字幕。

- 平台：iPadOS 17.4+
- 能力：本地英文识别 + 本地英中翻译，全程离线
- 构建：Mac 或 GitHub Actions 云端 Mac 上运行 `xcodegen generate && xcodebuild ...`
- 测试安装：免费 Apple ID + Sideloadly
```

- [ ] **Step 5: 在 Mac 上验证工程可生成、可编译**

Run: `xcodegen generate && xcodebuild -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'generic/platform=iOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add project.yml Sources README.md
git commit -m "chore: scaffold CaptionSubtitle app"
```

## Task 2: TranscriptProcessor（纯文本合并逻辑，TDD）

**Files:**
- Create: `Sources/CaptionCore/TranscriptProcessor.swift`
- Test: `Tests/CaptionCoreTests/TranscriptProcessorTests.swift`

- [ ] **Step 1: 写失败测试**

```swift
import XCTest
@testable import CaptionSubtitle

final class TranscriptProcessorTests: XCTestCase {
    func testPartialThenFinalReplacesText() {
        var processor = TranscriptProcessor()
        XCTAssertEqual(processor.merge(spoken: "Hello every", isFinal: false), "Hello every")
        XCTAssertEqual(processor.merge(spoken: "Hello everyone", isFinal: true), "Hello everyone")
    }

    func testEmptyPartialKeepsLastFinal() {
        var processor = TranscriptProcessor()
        _ = processor.merge(spoken: "Thanks", isFinal: true)
        XCTAssertEqual(processor.merge(spoken: "", isFinal: false), "Thanks")
    }

    func testResetClearsState() {
        var processor = TranscriptProcessor()
        _ = processor.merge(spoken: "Hi", isFinal: true)
        processor.reset()
        XCTAssertEqual(processor.merge(spoken: "", isFinal: false), "")
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: FAIL，`TranscriptProcessor` 未定义

- [ ] **Step 3: 实现 TranscriptProcessor**

```swift
import Foundation

struct TranscriptProcessor {
    private(set) var lastFinal = ""
    private(set) var current = ""

    mutating func merge(spoken text: String, isFinal: Bool) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isFinal {
            lastFinal = trimmed
            current = trimmed
        } else {
            current = trimmed.isEmpty ? lastFinal : trimmed
        }
        return current
    }

    mutating func reset() {
        lastFinal = ""
        current = ""
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/CaptionCore/TranscriptProcessor.swift Tests/CaptionCoreTests/TranscriptProcessorTests.swift
git commit -m "feat: add transcript merge logic"
```

## Task 3: 翻译服务（协议 + 本地实现，TDD）

**Files:**
- Create: `Sources/CaptionCore/TranslationService.swift`
- Create: `Tests/CaptionCoreTests/CaptionSessionTests.swift`（先放 mock 翻译器）

- [ ] **Step 1: 写失败测试（mock 翻译器）**

```swift
import XCTest
@testable import CaptionSubtitle

final class TranslationServiceTests: XCTestCase {
    func testMockTranslatorReturnsExpectedText() async throws {
        let translator = MockTranslating(result: "你好")
        let text = try await translator.translate("Hello")
        XCTAssertEqual(text, "你好")
    }
}

private struct MockTranslating: Translating {
    let result: String
    func translate(_ text: String) async throws -> String {
        result
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: FAIL，`Translating` 未定义

- [ ] **Step 3: 实现 Translating 协议和本地翻译服务**

```swift
import Foundation
import Translation

protocol Translating {
    func translate(_ text: String) async throws -> String
}

enum TranslationError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "当前设备暂不支持英中翻译，请确认系统为 iPadOS 17.4 或更高版本。"
        }
    }
}

final class OnDeviceTranslationService: Translating {
    private let source = Locale.Language(identifier: "en-US")
    private let target = Locale.Language(identifier: "zh-Hans")
    private var session: TranslationSession?

    func translate(_ text: String) async throws -> String {
        guard TranslationSession.isTranslationSupported(with: .init(source: source, target: target)) else {
            throw TranslationError.unavailable
        }
        if session == nil {
            session = try await TranslationSession(source: source, target: target)
        }
        guard let session else {
            throw TranslationError.unavailable
        }
        let response = try await session.translate(text)
        return response.targetText
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/CaptionCore/TranslationService.swift Tests/CaptionCoreTests/CaptionSessionTests.swift
git commit -m "feat: add on-device translation service"
```

## Task 4: 音频与语音识别服务

**Files:**
- Create: `Sources/CaptionCore/AudioCaptureService.swift`
- Create: `Sources/CaptionCore/SpeechRecognitionService.swift`

- [ ] **Step 1: 实现 AudioCaptureService**

```swift
import AVFoundation
import Foundation

protocol AudioCapturing: AnyObject {
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)? { get set }
    func start() throws
    func stop()
}

final class AudioCaptureService: AudioCapturing {
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    private let engine = AVAudioEngine()

    func start() throws {
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.onBuffer?(buffer, time)
        }
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
```

- [ ] **Step 2: 实现 SpeechRecognitionService**

```swift
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
```

- [ ] **Step 3: Commit**

```bash
git add Sources/CaptionCore/AudioCaptureService.swift Sources/CaptionCore/SpeechRecognitionService.swift
git commit -m "feat: add audio capture and speech recognition services"
```

## Task 5: 权限检查

**Files:**
- Create: `Sources/CaptionCore/PermissionChecker.swift`

- [ ] **Step 1: 实现 PermissionChecker**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add Sources/CaptionCore/PermissionChecker.swift
git commit -m "feat: add microphone and speech permissions"
```

## Task 6: CaptionSession（TDD）

**Files:**
- Modify: `Tests/CaptionCoreTests/CaptionSessionTests.swift`
- Create: `Sources/CaptionCore/CaptionSession.swift`

- [ ] **Step 1: 写失败测试**

```swift
import AVFoundation
import XCTest
@testable import CaptionSubtitle

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
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: FAIL，`CaptionSession` 未定义

- [ ] **Step 3: 实现 CaptionSession**

```swift
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'platform=iOS Simulator,name=iPad (10th generation)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/CaptionCore/CaptionSession.swift Tests/CaptionCoreTests/CaptionSessionTests.swift
git commit -m "feat: add caption session state machine"
```

## Task 7: 界面（A 方案字幕布局）

**Files:**
- Create: `Sources/CaptionUI/SettingsStore.swift`
- Create: `Sources/CaptionUI/CaptionView.swift`
- Create: `Sources/CaptionUI/ControlsView.swift`
- Modify: `Sources/CaptionApp/ContentView.swift`

- [ ] **Step 1: 实现 SettingsStore**

```swift
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: Keys.fontSize) }
    }
    @Published var showsEnglish: Bool {
        didSet { UserDefaults.standard.set(showsEnglish, forKey: Keys.showsEnglish) }
    }

    private enum Keys {
        static let fontSize = "settings.fontSize"
        static let showsEnglish = "settings.showsEnglish"
    }

    init() {
        let defaults = UserDefaults.standard
        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 26
        showsEnglish = defaults.object(forKey: Keys.showsEnglish) as? Bool ?? true
    }
}
```

- [ ] **Step 2: 实现 ControlsView**

```swift
import SwiftUI

struct ControlsView: View {
    @ObservedObject var session: CaptionSession
    @ObservedObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task { await session.start() }
            } label: {
                Label("聆听", systemImage: "mic.fill")
            }
            .disabled(session.state == .listening)

            Button {
                session.stop()
            } label: {
                Label("停止", systemImage: "stop.fill")
            }
            .disabled(session.state != .listening)

            Spacer()

            Button {
                settings.showsEnglish.toggle()
            } label: {
                Image(systemName: settings.showsEnglish ? "textformat.abc" : "textformat")
            }

            Button {
                settings.fontSize = max(18, settings.fontSize - 2)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }

            Button {
                settings.fontSize = min(40, settings.fontSize + 2)
            } label: {
                Image(systemName: "textformat.size.larger")
            }

            Button {
                session.clear()
            } label: {
                Image(systemName: "trash")
            }
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
```

- [ ] **Step 3: 实现 CaptionView**

```swift
import SwiftUI
import UIKit

struct CaptionView: View {
    @ObservedObject var session: CaptionSession
    @ObservedObject var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ControlsView(session: session, settings: settings)
                Spacer()
                captionBand
            }

            if let message = session.errorMessage {
                errorBanner(message)
            }
        }
    }

    private var captionBand: some View {
        VStack(alignment: .leading, spacing: 8) {
            if settings.showsEnglish, !session.caption.english.isEmpty {
                Text(session.caption.english)
                    .font(.system(size: max(settings.fontSize * 0.5, 12)))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(session.caption.chinese.isEmpty ? "等待字幕…" : session.caption.chinese)
                .font(.system(size: settings.fontSize, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.55))
    }

    private func errorBanner(_ message: String) -> some View {
        VStack(spacing: 10) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            Button("打开系统设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
```

- [ ] **Step 4: 替换 ContentView**

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var session = CaptionSession()

    var body: some View {
        CaptionView(session: session, settings: settings)
    }
}
```

- [ ] **Step 5: 在 Mac 上编译验证**

Run: `xcodegen generate && xcodebuild -project CaptionSubtitle.xcodeproj -scheme CaptionSubtitle -destination 'generic/platform=iOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add Sources/CaptionUI Sources/CaptionApp/ContentView.swift
git commit -m "feat: add bilingual caption UI"
```

## Task 8: 云端构建与 Windows 安装说明

**Files:**
- Create: `.github/workflows/build-ipa.yml`
- Modify: `README.md`

- [ ] **Step 1: 创建 GitHub Actions 工作流**

```yaml
name: Build IPA

on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  test-and-build:
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate project
        run: xcodegen generate

      - name: Run tests
        run: |
          xcodebuild test -project CaptionSubtitle.xcodeproj \
            -scheme CaptionSubtitle \
            -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
            CODE_SIGNING_ALLOWED=NO

      - name: Build unsigned app
        run: |
          xcodebuild -project CaptionSubtitle.xcodeproj \
            -scheme CaptionSubtitle \
            -configuration Debug \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build \
            CODE_SIGNING_ALLOWED=NO build

      - name: Package IPA
        run: |
          mkdir -p Payload
          cp -R build/Build/Products/Debug-iphoneos/CaptionSubtitle.app Payload/
          zip -r CaptionSubtitle-unsigned.ipa Payload

      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: caption-subtitle-unsigned
          path: CaptionSubtitle-unsigned.ipa
```

- [ ] **Step 2: 更新 README 安装说明**

```markdown
# 会议字幕

iPad 应用：分屏参加 Zoom 英文会议时，通过麦克风聆听扬声器声音，实时显示中文翻译字幕。

## 功能

- 本地英文语音识别 + 本地英中翻译，全程离线
- A 方案字幕布局：底部通栏，中文大字、英文小字在上
- 控制：开始/停止、字号、显示/隐藏英文、清空
- 最低系统：iPadOS 17.4+

## 在 Windows 上安装到 iPad（免费 Apple ID）

1. 将本仓库推送到 GitHub。
2. 打开 GitHub 仓库的 Actions 页面，运行 `Build IPA`，等待构建完成。
3. 下载 `caption-subtitle-unsigned` 构建产物里的 `.ipa`。
4. Windows 上安装 Sideloadly（https://sideloadly.io）。
5. iPad 连接电脑，打开 iTunes/Finder 信任电脑。
6. Sideloadly 中填写 Apple ID 和密码，拖入 `.ipa`，点击 Start。
7. iPad 上到“设置 → 通用 → VPN 与设备管理”信任开发者证书。
8. 打开“会议字幕”即可使用。

免费 Apple ID 签名的有效期是 7 天，过期后重复第 3-6 步重新安装。

## 在 Mac 上构建

```bash
brew install xcodegen
xcodegen generate
open CaptionSubtitle.xcodeproj
```

选择 iPad 模拟器或真机运行。
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build-ipa.yml README.md
git commit -m "ci: add cloud IPA build and Windows install guide"
```

## Task 9: 最终验证与收尾

**Files:** 无新增

- [ ] **Step 1: 结构性检查**

Run: `git status --short` 和 `git log --oneline`
Expected: 全部任务已提交，工作区干净

- [ ] **Step 2: 检查关键文件齐全**

Run: `Test-Path project.yml; Test-Path Sources/CaptionApp/CaptionApp.swift; Test-Path Sources/CaptionCore/CaptionSession.swift; Test-Path .github/workflows/build-ipa.yml; Test-Path README.md`
Expected: 全部 `True`

- [ ] **Step 3: 云端验证说明**

由于当前开发机是 Windows，无法直接运行 Xcode。真机行为验证必须在云端 GitHub Actions 或任意一台 Mac 上执行 Task 1 Step 5 和 Task 7 Step 5 的构建命令，以及 Task 2/3/6 的测试命令。发现编译错误时回到对应任务修复并重新提交。
