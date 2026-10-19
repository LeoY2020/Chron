import Foundation
import Combine
import AudioToolbox

/// 番茄钟阶段。
enum PomodoroPhase {
    case focus
    case breakTime

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .breakTime: return "Break"
        }
    }
}

/// 番茄钟状态模型：专注 / 休息循环，阶段完成后回调以便触感与记录。
final class PomodoroModel: ObservableObject {
    @Published var focusDuration: TimeInterval
    @Published var breakDuration: TimeInterval
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusCount = 0

    /// 阶段完成回调：参数为刚结束的阶段。
    var onPhaseComplete: ((PomodoroPhase) -> Void)?

    private var endDate: Date?
    private var timer: Timer?
    private var startedFocusDuration: TimeInterval = 0

    init(focus: TimeInterval, breakDuration: TimeInterval) {
        self.focusDuration = focus
        self.breakDuration = breakDuration
        self.remaining = focus
    }

    var progress: Double {
        let length = currentPhaseDuration
        guard length > 0 else { return 0 }
        return max(0, min(1, 1 - remaining / length))
    }

    var currentPhaseDuration: TimeInterval {
        phase == .focus ? focusDuration : breakDuration
    }

    func start() {
        guard remaining > 0 else { return }
        if phase == .focus { startedFocusDuration = focusDuration }
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

    /// 放弃当前轮次，回到该阶段初始状态。
    func abandon() {
        if phase == .focus, startedFocusDuration > 0, isRunning {
            let elapsed = max(0, focusDuration - remaining)
            if elapsed >= 60 {
                PersistenceManager.shared.add(
                    FocusSession(duration: elapsed, completed: false)
                )
            }
        }
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
        remaining = currentPhaseDuration
    }

    /// 跳过当前阶段。
    func skip() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
        advancePhase(completed: false)
    }

    /// 编辑时长（仅在未运行时允许）。
    func setDurations(focus: TimeInterval, breakDuration: TimeInterval) {
        self.focusDuration = focus
        self.breakDuration = breakDuration
        if !isRunning { remaining = currentPhaseDuration }
    }

    private func schedule() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 {
            timer?.invalidate()
            timer = nil
            self.endDate = nil
            isRunning = false
            remaining = 0
            advancePhase(completed: true)
        } else {
            remaining = left
        }
    }

    private func advancePhase(completed: Bool) {
        if phase == .focus {
            if completed, startedFocusDuration > 0 {
                PersistenceManager.shared.add(
                    FocusSession(duration: startedFocusDuration, completed: true)
                )
                completedFocusCount += 1
            }
            let finished = PomodoroPhase.focus
            phase = .breakTime
            remaining = breakDuration
            AudioToolbox.AudioServicesPlaySystemSound(1057)
            onPhaseComplete?(finished)
        } else {
            let finished = PomodoroPhase.breakTime
            phase = .focus
            startedFocusDuration = focusDuration
            remaining = focusDuration
            AudioToolbox.AudioServicesPlaySystemSound(1001)
            onPhaseComplete?(finished)
        }
    }
}

