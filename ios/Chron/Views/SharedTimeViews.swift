import SwiftUI

/// 居中大号数字：圆体、等宽数字，按屏幕短边自适应缩放，数字变化时轻微翻转过渡。
struct TimeDigitsView: View {
    let text: String
    let color: Color
    /// 相对屏幕短边的字号比例。
    var relativeSize: CGFloat = 0.26

    var body: some View {
        GeometryReader { geo in
            let short = min(geo.size.width, geo.size.height)
            let density: CGFloat = text.count > 5 ? 0.7 : 1
            let size = short * relativeSize * density
            Text(text)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.22), value: text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
        }
    }
}

/// Immersive：字形拉伸至贴近屏幕边缘，遵循安全区（不越入刘海 / 圆角），绝不裁切。
struct ImmersiveTimeView: View {
    let text: String
    let color: Color
    /// 期望横向占比（0-1），为圆角与安全边距留白。
    var horizontalFill: CGFloat = 0.94

    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            let availableWidth = (geo.size.width - insets.leading - insets.trailing) * horizontalFill
            let availableHeight = geo.size.height - insets.top - insets.bottom
            let count = max(1, CGFloat(text.count))
            // 宽高双重约束：既不横向溢出，也不纵向溢出。
            let byWidth = availableWidth / (count * 0.58)
            let byHeight = availableHeight * 0.44
            let size = max(24, min(byWidth, byHeight))
            Text(text)
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.04)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.22), value: text)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 倒置三角形指针（番茄钟刻度尺上方使用）。
struct InvertedTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 细渐变遮罩：底部面板滑入时压暗内容。
struct BottomScrim: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, Color.black.opacity(0.55), Color.black.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
