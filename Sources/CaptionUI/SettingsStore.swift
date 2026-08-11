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
