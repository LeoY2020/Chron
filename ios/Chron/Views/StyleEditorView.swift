import SwiftUI

/// 就地样式编辑器：字号颜色、圆环线宽、背景透明度。展开 / 收起使用淡入淡出。
struct StyleEditorView: View {
    @ObservedObject var settings: ChronSettings
    let isCountdown: Bool

    private let swatches = ["F5F5F7", "FFD36E", "FF8A3D", "FF6B6B", "7EC8FF", "9B8CFF", "6EE7B7", "FFFFFF"]

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
                        .onTapGesture { setColor(hex) }
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

            HStack(spacing: 12) {
                Text("Backdrop")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Slider(value: $settings.backgroundOpacity, in: 0...0.6)
            }
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
