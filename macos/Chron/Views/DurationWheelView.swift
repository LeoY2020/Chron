import SwiftUI
import AppKit

/// 倒计时时长选择（桌面）：时 / 分 / 秒 三段滚轮。
/// 支持滚轮滚动与按住拖拽，吸附到整格，每经过一格触发一次轻反馈，两端回弹。
struct DurationWheelView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack(spacing: 0) {
            DurationWheelColumn(range: 0...23, value: $hours, unit: "hours")
            DurationWheelColumn(range: 0...59, value: $minutes, unit: "min")
            DurationWheelColumn(range: 0...59, value: $seconds, unit: "sec")
        }
        .frame(height: 152)
    }
}

/// 单列时长滚轮：数字围绕中心吸附滚动，选中项放大高亮，其余渐隐。
struct DurationWheelColumn: View {
    let range: ClosedRange<Int>
    @Binding var value: Int
    let unit: String

    @State private var residual: CGFloat = 0
    private let itemHeight: CGFloat = 38

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ForEach(Array(range), id: \.self) { number in
                    let offset = CGFloat(number - value) * itemHeight + residual
                    Text("\(number)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(opacity(for: offset)))
                        .scaleEffect(scale(for: offset))
                        .offset(y: offset)
                        .opacity(abs(offset) < itemHeight * 2.7 ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: itemHeight * 3)
            .clipped()
            .overlay {
                WheelInputCatcher(
                    onScroll: { apply(-$0) },
                    onDrag: { apply($0) },
                    onEnded: { withAnimation(.easeOut(duration: 0.16)) { residual = 0 } }
                )
            }

            Text(unit)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    /// delta 为正表示数值增大。逐格吸附，边界处回弹而非反向。
    private func apply(_ delta: CGFloat) {
        residual += delta
        while residual >= itemHeight {
            if value >= range.upperBound {
                residual = 0
                return
            }
            value += 1
            HapticsManager.shared.impact(.light)
            residual -= itemHeight
        }
        while residual <= -itemHeight {
            if value <= range.lowerBound {
                residual = 0
                return
            }
            value -= 1
            HapticsManager.shared.impact(.light)
            residual += itemHeight
        }
    }

    private func opacity(for offset: CGFloat) -> Double {
        let distance = abs(offset) / itemHeight
        return Double(max(0.12, 1 - distance * 0.42))
    }

    private func scale(for offset: CGFloat) -> CGFloat {
        let distance = min(1, abs(offset) / (itemHeight * 1.6))
        return 1 - distance * 0.22
    }
}

/// 透明输入捕获层：把滚轮 / 拖拽的纵向增量转发给 SwiftUI 时长滚轮。
struct WheelInputCatcher: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void
    var onDrag: (CGFloat) -> Void
    var onEnded: () -> Void

    func makeNSView(context: Context) -> WheelCatcherView {
        let view = WheelCatcherView()
        view.onScroll = onScroll
        view.onDrag = onDrag
        view.onEnded = onEnded
        return view
    }

    func updateNSView(_ nsView: WheelCatcherView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onDrag = onDrag
        nsView.onEnded = onEnded
    }
}

/// 接收 scrollWheel 与 mouseDragged 的 AppKit 视图，不绘制内容。
final class WheelCatcherView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    var onDrag: ((CGFloat) -> Void)?
    var onEnded: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.scrollingDeltaY)
        if event.phase == .ended || event.momentumPhase == .ended {
            onEnded?()
        }
    }

    override func mouseDown(with event: NSEvent) {
        // 起点无需处理；滚动量由 mouseDragged 提供。
    }

    override func mouseDragged(with event: NSEvent) {
        onDrag?(event.deltaY)
    }

    override func mouseUp(with event: NSEvent) {
        onEnded?()
    }
}