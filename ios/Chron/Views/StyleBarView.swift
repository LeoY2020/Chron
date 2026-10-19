import SwiftUI

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
                    let active = chip.id == selectedID
                    Button {
                        HapticsManager.shared.impact(.light)
                        if active { onEdit() } else { onSelect(chip.id) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: chip.symbol)
                                .font(.system(size: 18, weight: .medium))
                            Text(chip.title)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .frame(width: 78, height: 58)
                        .foregroundStyle(active ? Color.black : Color.white.opacity(0.8))
                        .background(
                            active ? Color.white : Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
