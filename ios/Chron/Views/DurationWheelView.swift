import SwiftUI

/// 倒计时时长选择：时 / 分 / 秒 三段原生滚轮，惯性吸附，每格触发轻触感。
struct DurationWheelView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack(spacing: 0) {
            wheel(0..<24, value: $hours, unit: "h")
            wheel(0..<60, value: $minutes, unit: "m")
            wheel(0..<60, value: $seconds, unit: "s")
        }
        .frame(height: 148)
        .environment(\.colorScheme, .dark)
        .onChange(of: hours) { _, _ in HapticsManager.shared.impact(.light) }
        .onChange(of: minutes) { _, _ in HapticsManager.shared.impact(.light) }
        .onChange(of: seconds) { _, _ in HapticsManager.shared.impact(.light) }
    }

    private func wheel(_ range: Range<Int>, value: Binding<Int>, unit: String) -> some View {
        Picker(unit, selection: value) {
            ForEach(Array(range), id: \.self) { number in
                Text("\(number)\(unit)").tag(number)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
