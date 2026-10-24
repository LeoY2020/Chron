import SwiftUI
import AppKit

/// 倒计时页：五种样式，数字为主视觉；长按进入的样式栏由 RootView 统一呈现。
struct CountdownView: View {
    @ObservedObject var model: CountdownModel
    @ObservedObject var settings: ChronSettings
    let shrunk: Bool

    @State private var hoveredControl: String?

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
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "play" ? 0.16 : 0.1)))
                    .shadow(color: Color.white.opacity(hoveredControl == "play" ? 0.08 : 0), radius: 12)
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("play", $0) }

            Button {
                HapticsManager.shared.impact(.light)
                model.reset(to: settings.countdownDuration)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "reset" ? 0.12 : 0.06)))
                    .shadow(color: Color.white.opacity(hoveredControl == "reset" ? 0.06 : 0), radius: 10)
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("reset", $0) }
        }
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveredControl)
    }

    /// 记录当前悬停的高亮控件（光标切换由 pointerHover 扩展完成）。
    private func setHover(_ id: String, _ inside: Bool) {
        hoveredControl = inside ? id : (hoveredControl == id ? nil : hoveredControl)
    }
}