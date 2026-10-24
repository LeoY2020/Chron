import SwiftUI
import AppKit

/// 就地样式编辑器：字号颜色、圆环线宽、背景透明度。展开 / 收起使用淡入淡出。
struct StyleEditorView: View {
    @ObservedObject var settings: ChronSettings
    let isCountdown: Bool

    private let swatches = ["F5F5F7", "FFD36E", "FF8A3D", "FF6B6B", "7EC8FF", "9B8CFF", "6EE7B7", "FFFFFF"]

    @State private var hoveredHex: String?
    @State private var hoveringRing = false
    @State private var hoveringBackdrop = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                ForEach(swatches, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: currentHex == hex ? 2 : 0)
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(hoveredHex == hex ? 0.45 : 0), lineWidth: 1)
                        )
                        .scaleEffect(hoveredHex == hex ? 1.12 : 1)
                        .contentShape(Circle())
                        .onTapGesture { setColor(hex) }
                        .onHover { inside in
                            hoveredHex = inside ? hex : (hoveredHex == hex ? nil : hoveredHex)
                            if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
                        }
                        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveredHex)
                }
            }

            HStack(spacing: 12) {
                Text("Ring")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Slider(value: $settings.ringThickness, in: 3...30)
                Text("\(Int(settings.ringThickness))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 28, alignment: .trailing)
            }
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(hoveringRing ? 0.06 : 0))
            )
            .onHover { inside in
                hoveringRing = inside
                if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
            }
            .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveringRing)

            HStack(spacing: 12) {
                Text("Backdrop")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Slider(value: $settings.backgroundOpacity, in: 0...0.6)
            }
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(hoveringBackdrop ? 0.06 : 0))
            )
            .onHover { inside in
                hoveringBackdrop = inside
                if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
            }
            .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveringBackdrop)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    private var currentHex: String {
        isCountdown ? settings.countdownColorHex : settings.clockColorHex
    }

    private func setColor(_ hex: String) {
        HapticsManager.shared.impact(.light)
        if isCountdown {
            settings.countdownColorHex = hex
        } else {
            settings.clockColorHex = hex
        }
    }
}
