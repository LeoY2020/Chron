import SwiftUI

/// 番茄钟时长刻度尺：无数字刻度，上方倒三角指针，横向拖动实时改时长，
/// 每经过一格触发一次轻触感（不在滚动过程中连续振动）。
struct TickScalePicker: View {
    @Binding var minutes: Int
    let range: ClosedRange<Int>
    let accent: Color

    @State private var dragStartMinutes: Int?

    private let pointsPerMinute: CGFloat = 12
    private let majorEvery = 5

    var body: some View {
        VStack(spacing: 6) {
            InvertedTriangle()
                .fill(accent)
                .frame(width: 18, height: 12)

            Canvas { ctx, size in
                let centerX = size.width / 2
                let visible = Int(size.width / pointsPerMinute / 2) + 3
                let lower = max(range.lowerBound, minutes - visible)
                let upper = min(range.upperBound, minutes + visible)
                guard lower <= upper else { return }

                for value in lower...upper {
                    let x = centerX + CGFloat(value - minutes) * pointsPerMinute
                    let isMajor = value % majorEvery == 0
                    let height = size.height * (isMajor ? 0.72 : 0.34)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height - height))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(
                        path,
                        with: .color(accent.opacity(isMajor ? 0.85 : 0.3)),
                        lineWidth: isMajor ? 2 : 1
                    )
                }

                var centerTick = Path()
                centerTick.move(to: CGPoint(x: centerX, y: 0))
                centerTick.addLine(to: CGPoint(x: centerX, y: size.height))
                ctx.stroke(centerTick, with: .color(accent.opacity(0.9)), lineWidth: 1.5)
            }
            .frame(height: 84)
        }
        .contentShape(Rectangle())
        // 高优先级：拖动刻度尺时不被外层分页手势抢走。
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    if dragStartMinutes == nil { dragStartMinutes = minutes }
                    guard let start = dragStartMinutes else { return }
                    let delta = Int((-value.translation.width / pointsPerMinute).rounded())
                    let newValue = min(range.upperBound, max(range.lowerBound, start + delta))
                    if newValue != minutes {
                        minutes = newValue
                        HapticsManager.shared.impact(.light)
                    }
                }
                .onEnded { _ in dragStartMinutes = nil }
        )
    }
}
