import SwiftUI
import Foundation

/// 下拉专注摘要：今日 / 本周专注概览与最近七天趋势，克制、信息化而非数据看板。
struct FocusSummaryView: View {
    @ObservedObject var persistence: PersistenceManager
    let accent: Color
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Focus")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 28) {
                stat(value: "\(persistence.completedCount(on: Date()))", label: "Rounds today")
                stat(value: TimeFormat.humanized(persistence.totalFocus(on: Date())), label: "Focus today")
                stat(value: TimeFormat.humanized(persistence.totalFocusThisWeek()), label: "This week")
            }

            trend
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var trend: some View {
        let totals = persistence.lastSevenDaysTotals()
        let maxValue = max(totals.map { $0.total }.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(totals.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(accent.opacity(0.85))
                        .frame(height: max(4, CGFloat(item.total / maxValue) * 60))
                    Text(weekdayLabel(item.date))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 84, alignment: .bottom)
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}