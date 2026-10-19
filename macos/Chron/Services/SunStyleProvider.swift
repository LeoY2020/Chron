import SwiftUI
import Foundation

/// 一天中的光：随时刻平滑插值的调色板。
struct SunPalette {
    enum Phase {
        case night
        case dawn
        case day
        case dusk
    }

    let top: Color
    let bottom: Color
    let accent: Color
    let glyph: Color
    let phase: Phase

    /// 背景线性渐变。
    var gradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}

/// 依据当前时刻生成背景 / 前景光的预设，并在预设之间平滑插值（永不突兀）。
enum SunStyleProvider {
    private struct Keyframe {
        let hour: Double
        let top: (Double, Double, Double)
        let bottom: (Double, Double, Double)
        let accent: (Double, Double, Double)
        let glyph: (Double, Double, Double)
        let phase: SunPalette.Phase
    }

    /// 关键帧按时刻升序，0 与 24 首尾同色以保证环绕连续。
    private static let keyframes: [Keyframe] = [
        .init(hour: 0, top: (9, 11, 22), bottom: (2, 3, 8), accent: (96, 116, 176), glyph: (222, 230, 255), phase: .night),
        .init(hour: 5, top: (16, 16, 30), bottom: (4, 4, 12), accent: (140, 120, 170), glyph: (232, 232, 248), phase: .night),
        .init(hour: 7, top: (48, 32, 52), bottom: (12, 12, 26), accent: (244, 156, 112), glyph: (255, 230, 214), phase: .dawn),
        .init(hour: 12, top: (26, 44, 78), bottom: (10, 16, 34), accent: (122, 192, 255), glyph: (242, 248, 255), phase: .day),
        .init(hour: 16, top: (30, 44, 70), bottom: (10, 15, 30), accent: (255, 196, 120), glyph: (248, 246, 240), phase: .day),
        .init(hour: 19, top: (62, 36, 50), bottom: (14, 10, 22), accent: (255, 150, 92), glyph: (255, 226, 202), phase: .dusk),
        .init(hour: 21, top: (24, 20, 38), bottom: (6, 6, 16), accent: (150, 130, 190), glyph: (236, 232, 250), phase: .night),
        .init(hour: 24, top: (9, 11, 22), bottom: (2, 3, 8), accent: (96, 116, 176), glyph: (222, 230, 255), phase: .night)
    ]

    static func palette(for date: Date, calendar: Calendar = .current) -> SunPalette {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let t = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0

        var lower = keyframes[0]
        var upper = keyframes[keyframes.count - 1]
        for index in 0..<(keyframes.count - 1) {
            if t >= keyframes[index].hour && t <= keyframes[index + 1].hour {
                lower = keyframes[index]
                upper = keyframes[index + 1]
                break
            }
        }
        let span = max(0.0001, upper.hour - lower.hour)
        let raw = (t - lower.hour) / span
        let k = smoothstep(raw)

        let p = SunPalette(
            top: mix(lower.top, upper.top, k),
            bottom: mix(lower.bottom, upper.bottom, k),
            accent: mix(lower.accent, upper.accent, k),
            glyph: mix(lower.glyph, upper.glyph, k),
            phase: raw < 0.5 ? lower.phase : upper.phase
        )
        return p
    }

    private static func smoothstep(_ x: Double) -> Double {
        let c = max(0, min(1, x))
        return c * c * (3 - 2 * c)
    }

    private static func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ k: Double) -> Color {
        let r = (a.0 + (b.0 - a.0) * k) / 255
        let g = (a.1 + (b.1 - a.1) * k) / 255
        let bl = (a.2 + (b.2 - a.2) * k) / 255
        return Color(.sRGB, red: r, green: g, blue: bl, opacity: 1)
    }
}