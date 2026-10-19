import SwiftUI

/// Ring：12 点方向顺时针的圆环，随时间流逝逐渐耗尽。
struct RingCountdownView: View {
    let fraction: Double
    let color: Color
    let thickness: Double

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height) * 0.64
            ZStack {
                Circle()
                    .stroke(color.opacity(0.14), lineWidth: thickness)
                Circle()
                    .trim(from: 0, to: max(0.0001, min(1, fraction)))
                    .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Sector：全屏扇形进度，自 0 度扫过，橙黄到橙的渐变。
struct SectorCountdownView: View {
    /// 已流逝比例 0...1。
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.95
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let clamped = max(0, min(1, progress))
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * clamped),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(hex: "FFD36E"), Color(hex: "FF8A3D")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .ignoresSafeArea()
    }
}

/// Dial：倒计时指针在数字背后旋转，数字始终在前景。
struct DialCountdownView: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height) * 0.68
            let handLength = diameter / 2 * 0.84
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 1.5)

                ForEach(0..<60, id: \.self) { index in
                    let major = index % 5 == 0
                    Capsule()
                        .fill(color.opacity(major ? 0.55 : 0.22))
                        .frame(width: major ? 2 : 1, height: major ? 12 : 6)
                        .offset(y: -diameter / 2 + 10)
                        .rotationEffect(.degrees(Double(index) * 6))
                }

                Capsule()
                    .fill(color)
                    .frame(width: 3, height: handLength)
                    .offset(y: -handLength / 2)
                    .rotationEffect(.degrees(360 * max(0, min(1, progress))))
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
