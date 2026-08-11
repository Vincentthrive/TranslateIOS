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
