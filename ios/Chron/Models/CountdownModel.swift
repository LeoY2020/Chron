import Foundation
import Combine

/// 倒计时共享状态模型：以结束时刻为基准计算剩余，保证后台回前台后仍然准确。
final class CountdownModel: ObservableObject {
    @Published var total: TimeInterval
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false

    /// 归零回调（用于重触感 / 视觉提示）。
    var onFinish: (() -> Void)?

    private var endDate: Date?
    private var timer: Timer?

    init(total: TimeInterval) {
        self.total = total
        self.remaining = total
    }

    /// 已流逝比例 0...1。
    var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - remaining / total))
    }

    /// 剩余比例 0...1。
    var fraction: Double { 1 - progress }

    func start() {
        guard remaining > 0 else { return }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        schedule()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        if let endDate { remaining = max(0, endDate.timeIntervalSinceNow) }
        endDate = nil
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    /// 归零并可选设置新时长。
    func reset(to newTotal: TimeInterval? = nil) {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
        if let newTotal { total = max(1, newTotal) }
        remaining = total
    }

    private func schedule() {
        timer?.invalidate()
        // 以 0.1s 精度刷新，数字显示使用 TimelineView 做插值平滑。
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 {
            remaining = 0
            isRunning = false
            timer?.invalidate()
            timer = nil
            self.endDate = nil
            onFinish?()
        } else {
            remaining = left
        }
    }

    deinit {
        timer?.invalidate()
    }
}

