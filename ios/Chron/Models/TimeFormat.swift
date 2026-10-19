import Foundation

/// 时间文本格式化工具：所有数字均为等宽可对齐的字符串。
enum TimeFormat {
    /// 将剩余秒数格式化为 "HH:MM:SS" 或 "MM:SS"。
    static func duration(_ seconds: TimeInterval, forceHours: Bool = false) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 || forceHours {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    /// 大号数字用：稳定宽度、无 AM/PM 标记（12 小时制时小时不补零）。
    static func numericTime(_ date: Date, showSeconds: Bool, use24Hour: Bool, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        if use24Hour {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss" : "h:mm"
        }
        return formatter.string(from: date)
    }

    /// AM/PM 标记（24 小时制下为空字符串）。
    static func meridiem(_ date: Date, locale: Locale = .current) -> String {
        guard !uses24Hour(locale: locale) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .current
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    /// 是否使用 24 小时制。
    static func uses24Hour(locale: Locale = .current) -> Bool {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? "h"
        return !template.contains("a")
    }

    /// 人类可读时长，例如 "1h 25m" / "25m"。
    static func humanized(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
