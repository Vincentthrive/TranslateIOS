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
