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
            return "当前设备暂不支持英中翻译，请确认系统为 iPadOS 18.0 或更高版本。"
        }
    }
}

@available(iOS 18.0, *)
final class OnDeviceTranslationService: Translating {
    private let source = Locale.Language(identifier: "en-US")
    private let target = Locale.Language(identifier: "zh-Hans")
    private var session: TranslationSession?

    func translate(_ text: String) async throws -> String {
        guard await TranslationSession.isAvailable else {
            throw TranslationError.unavailable
        }
        if session == nil {
            let config = TranslationSession.Configuration(sourceLanguage: source, targetLanguage: target)
            session = try await TranslationSession(configuration: config)
        }
        guard let session else {
            throw TranslationError.unavailable
        }
        let response = try await session.translate(text)
        return response.targetText
    }
}
