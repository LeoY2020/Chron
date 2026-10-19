import SwiftUI

/// 时钟页：五种样式，含随时间平滑变化的 Sun 光。
struct ClockView: View {
    @ObservedObject var settings: ChronSettings

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(date: context.date)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func content(date: Date) -> some View {
        let use24Hour = TimeFormat.uses24Hour()
        let accent = Color(hex: settings.clockColorHex)

        ZStack {
            if settings.clockStyle == .sun {
                SunClockView(date: date, use24Hour: use24Hour)
            } else {
                background
                switch settings.clockStyle {
                case .analog:
                    AnalogClockView(color: accent)
                case .plain:
                    TimeDigitsView(
                        text: TimeFormat.numericTime(date, showSeconds: true, use24Hour: use24Hour),
                        color: accent
                    )
                    .overlay(alignment: .bottom) {
                        if use24Hour {
                            EmptyView()
                        } else {
                            Text(TimeFormat.meridiem(date))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(accent.opacity(0.7))
                                .padding(.bottom, 90)
                        }
                    }
                case .immersive:
                    ImmersiveTimeView(
                        text: TimeFormat.numericTime(date, showSeconds: false, use24Hour: use24Hour),
                        color: accent
                    )
                case .sevenSegment:
                    SevenSegmentView(
                        text: TimeFormat.numericTime(date, showSeconds: false, use24Hour: use24Hour),
                        color: accent
                    )
                    .padding(.vertical, 56)
                    .padding(.horizontal, 16)
                case .sun:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var background: some View {
        ZStack {
            Color.black
            if settings.backgroundOpacity > 0.001 {
                Color(hex: "12141C").opacity(settings.backgroundOpacity)
            }
        }
        .ignoresSafeArea()
    }
}
