import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var session = CaptionSession()

    var body: some View {
        CaptionView(session: session, settings: settings)
    }
}
