import SwiftUI

/// 倒计时页：五种样式，数字为主视觉；长按进入的样式栏由 RootView 统一呈现。
struct CountdownView: View {
    @ObservedObject var model: CountdownModel
    @ObservedObject var settings: ChronSettings
    let shrunk: Bool

    var body: some View {
        ZStack {
            background

            if settings.countdownStyle == .immersive {
                ImmersiveTimeView(text: TimeFormat.duration(model.remaining), color: accent)
            } else {
                styleLayer
                TimeDigitsView(text: TimeFormat.duration(model.remaining), color: accent)
            }

            if !shrunk {
                VStack {
                    Spacer()
                    controls
                        .padding(.bottom, 46)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accent: Color { Color(hex: settings.countdownColorHex) }

    private var background: some View {
        ZStack {
            Color.black
            if settings.backgroundOpacity > 0.001 {
                Color(hex: "12141C").opacity(settings.backgroundOpacity)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var styleLayer: some View {
        switch settings.countdownStyle {
        case .ring:
            RingCountdownView(fraction: model.fraction, color: accent, thickness: settings.ringThickness)
        case .sector:
            SectorCountdownView(progress: model.progress)
        case .dial:
            DialCountdownView(progress: model.progress, color: accent)
        case .plain, .immersive:
            EmptyView()
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button {
                HapticsManager.shared.impact(.medium)
                model.toggle()
            } label: {
                Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)

            Button {
                HapticsManager.shared.impact(.light)
                model.reset(to: settings.countdownDuration)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
    }
}