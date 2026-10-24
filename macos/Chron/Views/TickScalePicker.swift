import SwiftUI
import AppKit

/// 番茄钟时长刻度尺：无数字刻度，上方倒三角指针，横向拖动实时改时长，
/// 每经过一格触发一次轻反馈（不在滚动过程中连续振动）。
struct TickScalePicker: View {
    @Binding var minutes: Int
    let range: ClosedRange<Int>
    let accent: Color

    @State private var dragStartMinutes: Int?
    @State private var wheel = WheelHoverAdjuster()

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
        .onContinuousHover { phase in
            switch phase {
            case .active(_):
                wheel.isHovering = true
            case .ended:
                wheel.isHovering = false
            }
        }
        .onAppear {
            // 只捕获 Binding 与常量范围，避免闭包反向持有视图。
            let binding = $minutes
            let limits = range
            wheel.onStep = { step in
                let current = binding.wrappedValue
                let newValue = min(limits.upperBound, max(limits.lowerBound, current + step))
                guard newValue != current else { return }
                binding.wrappedValue = newValue
                HapticsManager.shared.impact(.light)
            }
            wheel.start()
        }
        .onDisappear {
            wheel.onStep = nil
            wheel.stop()
        }
    }
}

/// 悬停时用滚轮微调；只在指针位于刻度尺内时吞掉纵向滚动，避免干扰横向分页。
private final class WheelHoverAdjuster: NSObject {
    var isHovering = false
    var onStep: ((Int) -> Void)?

    private var monitor: Any?
    private var accum: CGFloat = 0

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.isHovering else { return event }
            let dx = event.scrollingDeltaX
            let dy = event.scrollingDeltaY
            guard abs(dy) > abs(dx), abs(dy) > 0.01 else { return event }
            // 触控板按点数、普通滚轮按行数换算，保证一格≈一分钟的微调手感。
            let unit: CGFloat = event.hasPreciseScrollingDeltas ? 18 : 1
            self.accum += dy
            while self.accum >= unit {
                self.accum -= unit
                self.onStep?(1)
            }
            while self.accum <= -unit {
                self.accum += unit
                self.onStep?(-1)
            }
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        accum = 0
        isHovering = false
    }
}