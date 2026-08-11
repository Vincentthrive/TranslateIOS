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
