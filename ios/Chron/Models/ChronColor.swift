import SwiftUI
import Foundation

extension Color {
    /// 由 "#RRGGBB" / "RRGGBB" / "RRGGBBAA" 构造颜色；解析失败时回退为白色。
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else {
            self = .white
            return
        }
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        switch s.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
