import SwiftUI
import Foundation

/// 根视图：三页全屏水平分页（Countdown / Pomodoro / Clock）。
/// 长按 / 右键进入"收缩 + 底部样式栏"的原地设置状态，此时禁用分页。
struct RootView: View {
    @StateObject private var settings = ChronSettings.shared
    @StateObject private var persistence = PersistenceManager.shared
    @StateObject private var countdown: CountdownModel
    @StateObject private var pomodoro: PomodoroModel
    @StateObject private var state = RootState()
    @StateObject private var monitor = InputMonitor()
    @ObservedObject private var haptics = HapticsManager.shared

    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int

    init() {
        let settings = ChronSettings.shared
        _countdown = StateObject(wrappedValue: CountdownModel(total: settings.countdownDuration))
        _pomodoro = StateObject(wrappedValue: PomodoroModel(focus: settings.pomodoroFocus, breakDuration: settings.pomodoroBreak))
        let total = Int(settings.countdownDuration)
        _hours = State(initialValue: total / 3600)
        _minutes = State(initialValue: (total % 3600) / 60)
        _seconds = State(initialValue: total % 60)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                pager(width: geo.size.width)
                    .scaleEffect(state.shrunk ? 0.92 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: state.shrunk ? 30 : 0, style: .continuous))
                    .animation(.spring(response: 0.36, dampingFraction: 0.82), value: state.shrunk)

                pageIndicator
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 14)
                    .opacity(state.shrunk ? 0 : 1)

                if state.shrunk && state.page != 1 {
                    bottomPanel
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                HapticPulseLayer(
                    grade: haptics.lastGrade,
                    token: haptics.pulseID,
                    enabled: !haptics.reduceMotion
                )
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.82), value: state.shrunk)
            .onAppear { configure() }
            .onDisappear { monitor.stop() }
        }
        .frame(minWidth: 480, minHeight: 360)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func configure() {
        HapticsManager.shared.prepare()
        countdown.onFinish = { HapticsManager.shared.completion() }
        pomodoro.onPhaseComplete = { _ in HapticsManager.shared.completion() }

        monitor.onPageLeft = { state.goLeft() }
        monitor.onPageRight = { state.goRight() }
        monitor.onToggleShrink = { state.toggleShrink() }
        monitor.onTogglePlay = {
            guard !state.shrunk else { return }
            if state.page == 0 {
                countdown.toggle()
                HapticsManager.shared.impact(.medium)
            } else if state.page == 1 {
                pomodoro.toggle()
                HapticsManager.shared.impact(.medium)
            }
        }
        monitor.start()
    }

    // MARK: - Pager

    private func pager(width: CGFloat) -> some View {
        ZStack {
            CountdownView(model: countdown, settings: settings, shrunk: state.shrunk)
                .frame(width: width)
                .offset(x: CGFloat(0 - state.page) * width + state.dragOffset)

            PomodoroView(
                model: pomodoro,
                settings: settings,
                persistence: persistence,
                editingTime: $state.pomodoroEditing
            )
            .frame(width: width)
            .offset(x: CGFloat(1 - state.page) * width + state.dragOffset)

            ClockView(settings: settings)
                .frame(width: width)
                .offset(x: CGFloat(2 - state.page) * width + state.dragOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .simultaneousGesture(pagerGesture(width: width))
        .onLongPressGesture(minimumDuration: 0.45) {
            state.toggleShrink()
        }
        .onTapGesture {
            if state.shrunk { state.toggleShrink() }
        }
    }

    private func pagerGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                if state.shrunk || state.showEditor || state.pomodoroEditing { return }
                let raw = value.translation.width
                if abs(value.translation.height) > abs(raw) { state.dragOffset = 0; return }
                let atStart = state.page == 0 && raw > 0
                let atEnd = state.page == 2 && raw < 0
                state.dragOffset = (atStart || atEnd) ? raw * 0.28 : raw
            }
            .onEnded { value in
                if state.shrunk || state.showEditor || state.pomodoroEditing { return }
                let raw = value.translation.width
                let predicted = value.predictedEndTranslation.width
                let signal = abs(predicted) > abs(raw) ? predicted : raw
                let threshold = width * 0.22
                let oldPage = state.page
                var target = state.page
                if signal < -threshold, state.page < state.pageCount - 1 {
                    target = state.page + 1
                } else if signal > threshold, state.page > 0 {
                    target = state.page - 1
                }
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.32)) {
                    state.page = target
                    state.dragOffset = 0
                }
                if target != oldPage {
                    HapticsManager.shared.impact(.light)
                }
            }
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<state.pageCount, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index == state.page ? 0.55 : 0.18))
                    .frame(width: 5, height: 5)
            }
        }
    }

    // MARK: - Shrink / style panel

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            if state.showEditor {
                StyleEditorView(settings: settings, isCountdown: state.page == 0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            StyleBarView(chips: chips, selectedID: selectedID) { id in
                selectStyle(id)
            } onEdit: {
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.28)) { state.showEditor.toggle() }
            }

            if state.page == 0 && !countdown.isRunning {
                DurationWheelView(hours: $hours, minutes: $minutes, seconds: $seconds)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.bottom, 10)
        .background(alignment: .bottom) {
            BottomScrim()
                .frame(height: 280)
        }
        .environment(\.colorScheme, .dark)
        .onChange(of: hours) { _, _ in applyDuration() }
        .onChange(of: minutes) { _, _ in applyDuration() }
        .onChange(of: seconds) { _, _ in applyDuration() }
    }

    private var chips: [StyleChip] {
        if state.page == 0 {
            return CountdownStyle.allCases.map {
                StyleChip(id: $0.rawValue, title: $0.title, symbol: $0.symbol)
            }
        }
        return ClockStyle.allCases.map {
            StyleChip(id: $0.rawValue, title: $0.title, symbol: $0.symbol)
        }
    }

    private var selectedID: String {
        state.page == 0 ? settings.countdownStyle.rawValue : settings.clockStyle.rawValue
    }

    private func selectStyle(_ id: String) {
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.25)) { state.showEditor = false }
        if state.page == 0, let style = CountdownStyle(rawValue: id) {
            settings.countdownStyle = style
        } else if let style = ClockStyle(rawValue: id) {
            settings.clockStyle = style
        }
    }

    private func applyDuration() {
        let total = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        guard total > 0 else { return }
        settings.countdownDuration = total
        countdown.reset(to: total)
    }
}

/// 微视觉脉冲：以极低透明度白闪一层，替代桌面端缺失的触感。
private struct HapticPulseLayer: View {
    let grade: HapticsManager.Grade
    let token: Int
    let enabled: Bool

    var body: some View {
        if enabled && token > 0 {
            FlashView(intensity: intensity)
                .id(token)
        }
    }

    private var intensity: Double {
        switch grade {
        case .light: return 0.02
        case .medium: return 0.035
        case .heavy: return 0.05
        }
    }
}

private struct FlashView: View {
    let intensity: Double
    @State private var on = false

    var body: some View {
        Color.white
            .opacity(on ? intensity : 0)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                on = true
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.32)) { on = false }
                }
            }
    }
}