import SwiftUI
import AppKit

/// 番茄钟页：暖橙调，下拉展开专注摘要，点击时间进入刻度尺改时长。
struct PomodoroView: View {
    @ObservedObject var model: PomodoroModel
    @ObservedObject var settings: ChronSettings
    @ObservedObject var persistence: PersistenceManager

    @Binding var editingTime: Bool
    @State private var pickingMinutes = 25
    @State private var breakMinutes = 5
    @State private var summaryExpanded = false
    @State private var pullProgress: CGFloat = 0
    @State private var hoveredControl: String?

    private var accent: Color {
        model.phase == .focus ? Color(hex: "FF9F45") : Color(hex: "46C7B8")
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 22) {
                Spacer(minLength: 36)
                if !editingTime { phasePill }
                timeBlock
                if editingTime { editorBlock } else { controls }
                Spacer()
            }
            .padding(.horizontal, 24)

            if !summaryExpanded && pullProgress > 0 {
                VStack {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(Double(min(1, pullProgress / 120))))
                    Spacer()
                }
                .padding(.top, 10)
                .allowsHitTesting(false)
            }

            if summaryExpanded {
                VStack {
                    FocusSummaryView(persistence: persistence, accent: accent) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            summaryExpanded = false
                        }
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(pullGesture, including: (editingTime || summaryExpanded) ? .subviews : .all)
        .onAppear {
            pickingMinutes = min(180, max(5, Int(model.focusDuration / 60)))
            breakMinutes = min(60, max(1, Int(model.breakDuration / 60)))
        }
    }

    private var background: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [accent.opacity(0.16), .clear],
                center: .center,
                startRadius: 8,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private var phasePill: some View {
        Text(model.phase.title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(accent.opacity(0.14)))
    }

    private var timeBlock: some View {
        Button {
            guard !model.isRunning else { return }
            HapticsManager.shared.impact(.light)
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { editingTime = true }
        } label: {
            VStack(spacing: 8) {
                Text(TimeFormat.duration(model.remaining))
                    .font(.system(size: 84, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: model.remaining)
                if !editingTime {
                    Text("\(model.completedFocusCount) rounds this session")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(model.isRunning)
        .onHover { inside in
            // 运行中不可点击，不显示手型光标。
            if inside && !model.isRunning { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
    }

    private var editorBlock: some View {
        VStack(spacing: 18) {
            TickScalePicker(minutes: $pickingMinutes, range: 5...180, accent: accent)
                .frame(height: 108)

            breakRow

            HStack(spacing: 14) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { editingTime = false }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white.opacity(hoveredControl == "cancel" ? 0.14 : 0.08)))
                }
                .buttonStyle(.plain)
                .pointerHover { setHover("cancel", $0) }

                Button {
                    HapticsManager.shared.impact(.medium)
                    let seconds = TimeInterval(pickingMinutes * 60)
                    let breakSeconds = TimeInterval(breakMinutes * 60)
                    model.setDurations(focus: seconds, breakDuration: breakSeconds)
                    settings.pomodoroFocus = seconds
                    settings.pomodoroBreak = breakSeconds
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { editingTime = false }
                } label: {
                    Text("Set \(pickingMinutes) min")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(accent))
                        .overlay(Capsule().fill(Color.white.opacity(hoveredControl == "set" ? 0.12 : 0)))
                }
                .buttonStyle(.plain)
                .pointerHover { setHover("set", $0) }
            }
        }
        .transition(.opacity)
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveredControl)
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button {
                HapticsManager.shared.impact(.medium)
                model.toggle()
            } label: {
                Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(accent))
                    .overlay(Circle().fill(Color.white.opacity(hoveredControl == "play" ? 0.12 : 0)))
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("play", $0) }

            Button {
                HapticsManager.shared.impact(.light)
                model.abandon()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "abandon" ? 0.14 : 0.08)))
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("abandon", $0) }

            Button {
                HapticsManager.shared.impact(.light)
                model.skip()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "skip" ? 0.14 : 0.08)))
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("skip", $0) }
        }
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveredControl)
    }

    private var breakRow: some View {
        HStack(spacing: 16) {
            Text("Break")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Button {
                if breakMinutes > 1 {
                    breakMinutes -= 1
                    HapticsManager.shared.impact(.light)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "breakMinus" ? 0.14 : 0.08)))
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("breakMinus", $0) }
            Text("\(breakMinutes) min")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 62)
            Button {
                if breakMinutes < 60 {
                    breakMinutes += 1
                    HapticsManager.shared.impact(.light)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(hoveredControl == "breakPlus" ? 0.14 : 0.08)))
            }
            .buttonStyle(.plain)
            .pointerHover { setHover("breakPlus", $0) }
        }
        .padding(.horizontal, 4)
        .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.18), value: hoveredControl)
    }

    /// 记录当前悬停的高亮控件（光标切换由 pointerHover 扩展完成）。
    private func setHover(_ id: String, _ inside: Bool) {
        hoveredControl = inside ? id : (hoveredControl == id ? nil : hoveredControl)
    }

    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard !summaryExpanded else { return }
                guard abs(value.translation.height) >= abs(value.translation.width) else { return }
                pullProgress = max(0, min(value.translation.height, 220))
            }
            .onEnded { value in
                guard !summaryExpanded else { return }
                if value.translation.height > 120 {
                    HapticsManager.shared.impact(.medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        summaryExpanded = true
                    }
                }
                withAnimation(.easeOut(duration: 0.2)) { pullProgress = 0 }
            }
    }
}