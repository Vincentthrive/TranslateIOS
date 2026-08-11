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
