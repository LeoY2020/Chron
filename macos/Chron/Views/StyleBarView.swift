import SwiftUI
import AppKit

/// 样式栏条目。
struct StyleChip: Identifiable {
    let id: String
    let title: String
    let symbol: String
}

/// 底部样式栏：点选切换样式；再次点击当前样式进入就地编辑器。
struct StyleBarView: View {
    let chips: [StyleChip]
    let selectedID: String
    let onSelect: (String) -> Void
    let onEdit: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chips) { chip in
                    StyleChipButton(
                        chip: chip,
                        active: chip.id == selectedID
                    ) {
                        HapticsManager.shared.impact(.light)
                        if chip.id == selectedID { onEdit() } else { onSelect(chip.id) }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
    }
}

/// 单个样式条目：悬停提亮、轻微放大与手型光标；选中态为白底黑字。
private struct StyleChipButton: View {
    let chip: StyleChip
    let active: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: chip.symbol)
                    .font(.system(size: 18, weight: .medium))
                Text(chip.title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            .frame(width: 78, height: 58)
            .foregroundStyle(active ? Color.black : Color.white.opacity(0.8))
            .background(
                active
                    ? Color.white
                    : Color.white.opacity(hovering ? 0.14 : 0.08),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(active ? 0.35 : 0), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(active ? 0.25 : 0), radius: 10, x: 0, y: 3)
            .scaleEffect(hovering ? 1.03 : 1)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            hovering = inside
            if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hovering)
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: active)
    }
}
