import Foundation
import Combine

/// 全局设置：集中管理所有可持久化偏好，以 UserDefaults 落盘。
/// （在 ObservableObject 内不使用 @AppStorage，改用 @Published + didSet。）
final class ChronSettings: ObservableObject {
    static let shared = ChronSettings()

    private enum Key {
        static let countdownStyle = "chron.countdown.style"
        static let clockStyle = "chron.clock.style"
        static let countdownDuration = "chron.countdown.duration"
        static let countdownColor = "chron.countdown.color"
        static let clockColor = "chron.clock.color"
        static let backgroundOpacity = "chron.background.opacity"
        static let ringThickness = "chron.ring.thickness"
        static let pomodoroFocus = "chron.pomodoro.focus"
        static let pomodoroBreak = "chron.pomodoro.break"
    }

    private let defaults: UserDefaults

    @Published var countdownStyle: CountdownStyle {
        didSet { defaults.set(countdownStyle.rawValue, forKey: Key.countdownStyle) }
    }

    @Published var clockStyle: ClockStyle {
        didSet { defaults.set(clockStyle.rawValue, forKey: Key.clockStyle) }
    }

    /// 倒计时初始时长（秒）。
    @Published var countdownDuration: TimeInterval {
        didSet { defaults.set(countdownDuration, forKey: Key.countdownDuration) }
    }

    @Published var countdownColorHex: String {
        didSet { defaults.set(countdownColorHex, forKey: Key.countdownColor) }
    }

    @Published var clockColorHex: String {
        didSet { defaults.set(clockColorHex, forKey: Key.clockColor) }
    }

    /// 页面背景微透明度（0 = 纯黑）。
    @Published var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: Key.backgroundOpacity) }
    }

    /// 圆环 / 表盘进度线宽（pt）。
    @Published var ringThickness: Double {
        didSet { defaults.set(ringThickness, forKey: Key.ringThickness) }
    }

    /// 番茄钟专注时长（秒）。
    @Published var pomodoroFocus: TimeInterval {
        didSet { defaults.set(pomodoroFocus, forKey: Key.pomodoroFocus) }
    }

    /// 番茄钟休息时长（秒）。
    @Published var pomodoroBreak: TimeInterval {
        didSet { defaults.set(pomodoroBreak, forKey: Key.pomodoroBreak) }
    }

    private init() {
        let d = UserDefaults.standard
        self.defaults = d
        self.countdownStyle = CountdownStyle(rawValue: d.string(forKey: Key.countdownStyle) ?? "") ?? .ring
        self.clockStyle = ClockStyle(rawValue: d.string(forKey: Key.clockStyle) ?? "") ?? .analog
        self.countdownDuration = (d.object(forKey: Key.countdownDuration) as? Double) ?? 300
        self.countdownColorHex = d.string(forKey: Key.countdownColor) ?? "F5F5F7"
        self.clockColorHex = d.string(forKey: Key.clockColor) ?? "F5F5F7"
        self.backgroundOpacity = (d.object(forKey: Key.backgroundOpacity) as? Double) ?? 0
        self.ringThickness = (d.object(forKey: Key.ringThickness) as? Double) ?? 10
        self.pomodoroFocus = (d.object(forKey: Key.pomodoroFocus) as? Double) ?? 25 * 60
        self.pomodoroBreak = (d.object(forKey: Key.pomodoroBreak) as? Double) ?? 5 * 60
    }
}