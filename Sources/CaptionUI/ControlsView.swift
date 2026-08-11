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
