import SwiftUI
import Foundation

/// Analog：指针时钟，秒针连续平滑扫动（TimelineView(.animation)）。
struct AnalogClockView: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let date = context.date
                let comps = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
                let second = Double(comps.second ?? 0) + Double(comps.nanosecond ?? 0) / 1_000_000_000
                let minute = Double(comps.minute ?? 0) + second / 60
                let hour = Double(comps.hour ?? 0).truncatingRemainder(dividingBy: 12) + minute / 60

                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 * 0.86

                for index in 0..<60 {
                    let major = index % 5 == 0
                    let radians = Double(index) * 6 * .pi / 180
                    var tick = Path()
                    tick.move(to: point(center, radians, radius - (major ? 18 : 10)))
                    tick.addLine(to: point(center, radians, radius))
                    ctx.stroke(tick, with: .color(color.opacity(major ? 0.55 : 0.22)), lineWidth: major ? 2 : 1)
                }

                strokeHand(ctx, center: center, degrees: hour * 30, length: radius * 0.50, width: 7, color: color)
                strokeHand(ctx, center: center, degrees: minute * 6, length: radius * 0.72, width: 5, color: color)
                strokeHand(ctx, center: center, degrees: second * 6, length: radius * 0.84, width: 2, color: color.opacity(0.9))

                let dot = CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)
                ctx.fill(Path(ellipseIn: dot), with: .color(color))
            }
        }
    }

    private func point(_ center: CGPoint, _ radians: Double, _ distance: Double) -> CGPoint {
        CGPoint(x: center.x + distance * sin(radians), y: center.y - distance * cos(radians))
    }

    private func strokeHand(
        _ ctx: GraphicsContext,
        center: CGPoint,
        degrees: Double,
        length: Double,
        width: CGFloat,
        color: Color
    ) {
        let radians = degrees * .pi / 180
        var path = Path()
        path.move(to: center)
        path.addLine(to: point(center, radians, length))
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

/// Seven-segment：复古七段数码管，暗段保留微光以显结构。
struct SevenSegmentView: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                if character == ":" {
                    VStack(spacing: 14) {
                        Circle().fill(color).frame(width: 10, height: 10)
                        Circle().fill(color).frame(width: 10, height: 10)
                    }
                    .frame(width: 14)
                } else if let digit = character.wholeNumberValue, (0...9).contains(digit) {
                    SevenSegmentDigit(digit: digit, color: color)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

private enum SevenSegment: Hashable {
    case a, b, c, d, e, f, g
}

private struct SevenSegmentDigit: View {
    let digit: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t = w * 0.19
            let on = Self.segments(for: digit)
            ZStack {
                segment(on.contains(.a), CGRect(x: t, y: 0, width: w - 2 * t, height: t))
                segment(on.contains(.g), CGRect(x: t, y: (h - t) / 2, width: w - 2 * t, height: t))
                segment(on.contains(.d), CGRect(x: t, y: h - t, width: w - 2 * t, height: t))
                segment(on.contains(.f), CGRect(x: 0, y: t, width: t, height: (h - 3 * t) / 2))
                segment(on.contains(.b), CGRect(x: w - t, y: t, width: t, height: (h - 3 * t) / 2))
                segment(on.contains(.e), CGRect(x: 0, y: (h + t) / 2, width: t, height: (h - 3 * t) / 2))
                segment(on.contains(.c), CGRect(x: w - t, y: (h + t) / 2, width: t, height: (h - 3 * t) / 2))
            }
        }
        .aspectRatio(0.56, contentMode: .fit)
    }

    private func segment(_ isOn: Bool, _ rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: max(0, rect.width) / 2, style: .continuous)
            .fill(color.opacity(isOn ? 1 : 0.07))
            .frame(width: max(0, rect.width), height: max(0, rect.height))
            .position(x: rect.midX, y: rect.midY)
    }

    private static func segments(for digit: Int) -> Set<SevenSegment> {
        switch digit {
        case 0: return [.a, .b, .c, .d, .e, .f]
        case 1: return [.b, .c]
        case 2: return [.a, .b, .g, .e, .d]
        case 3: return [.a, .b, .g, .c, .d]
        case 4: return [.f, .g, .b, .c]
        case 5: return [.a, .f, .g, .c, .d]
        case 6: return [.a, .f, .g, .e, .c, .d]
        case 7: return [.a, .b, .c]
        case 8: return [.a, .b, .c, .d, .e, .f, .g]
        case 9: return [.a, .b, .c, .d, .f, .g]
        default: return []
        }
    }
}

/// Sun：依据当前时刻自动应用预设光，背景与字形柔和变化。
struct SunClockView: View {
    let date: Date
    let use24Hour: Bool

    var body: some View {
        let palette = SunStyleProvider.palette(for: date)
        ZStack {
            palette.gradient
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text(TimeFormat.numericTime(date, showSeconds: false, use24Hour: use24Hour))
                    .font(.system(size: 74, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.glyph)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: date)
                Text(phaseLabel(palette.phase))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.accent)
            }
            .padding(.horizontal, 24)
        }
    }

    private func phaseLabel(_ phase: SunPalette.Phase) -> String {
        switch phase {
        case .night: return "Night"
        case .dawn: return "Dawn"
        case .day: return "Day"
        case .dusk: return "Dusk"
        }
    }
}