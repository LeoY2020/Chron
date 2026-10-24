import SwiftUI
import AppKit
import Foundation

/// 根视图：三页全屏水平分页（Countdown / Pomodoro / Clock）。
/// 长按 / 右键进入"收缩 + 底部样式栏"的原地设置状态，此时禁用分页。
struct RootView: View {
    @StateObject private var settings = ChronSettings.shared
    @StateObject private var persistence = PersistenceManager.shared
    @StateObject private var countdown: CountdownModel
    @StateObject private var pomodoro: PomodoroModel
    @StateObject private var state = RootState.shared
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
                backdrop

                pager(width: geo.size.width)
                    .scaleEffect(state.shrunk ? 0.92 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: state.shrunk ? 30 : 0, style: .continuous))
                    .shadow(
                        color: Color.black.opacity(state.shrunk ? 0.5 : 0),
                        radius: state.shrunk ? 24 : 0,
                        x: 0,
                        y: state.shrunk ? 12 : 0
                    )
                    .animation(.spring(response: 0.36, dampingFraction: 0.82), value: state.shrunk)

                // 页面各自铺满不透明黑底，光晕必须叠在其上才可见；透明度极低，不影响阅读。
                ambientGlow
                    .allowsHitTesting(false)

                vignette
                    .opacity(state.shrunk ? 0 : 1)
                    .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3), value: state.shrunk)

                pageIndicator
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
                    .opacity(state.shrunk ? 0 : 1)
                    .allowsHitTesting(!state.shrunk)
                    .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3), value: state.shrunk)

                if state.shrunk && state.page != 1 {
                    bottomPanel
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                hintsBar

                HapticPulseLayer(
                    grade: haptics.lastGrade,
                    token: haptics.pulseID,
                    enabled: !haptics.reduceMotion
                )
            }
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

        // 菜单命令 / 快捷键动作统一挂到 RootState 上。
        // 闭包内直接读取单例、只弱捕获视图模型，避免单例长期持有模型造成泄漏。
        let countdownModel = countdown
        let pomodoroModel = pomodoro
        let settingsStore = settings

        state.onPrimary = { [weak countdownModel, weak pomodoroModel] in
            let state = RootState.shared
            guard !state.shrunk, !state.pomodoroEditing else { return }
            if state.page == 0 {
                countdownModel?.toggle()
                HapticsManager.shared.impact(.medium)
            } else if state.page == 1 {
                pomodoroModel?.toggle()
                HapticsManager.shared.impact(.medium)
            }
        }
        state.onReset = { [weak countdownModel, weak pomodoroModel, weak settingsStore] in
            let state = RootState.shared
            guard !state.showEditor else { return }
            if state.page == 0 {
                guard let countdownModel, let settingsStore else { return }
                countdownModel.reset(to: settingsStore.countdownDuration)
                HapticsManager.shared.impact(.light)
            } else if state.page == 1, !state.pomodoroEditing {
                guard let pomodoroModel else { return }
                // pause + setDurations 回到当前阶段起点，不写入任何完成记录。
                pomodoroModel.pause()
                pomodoroModel.setDurations(
                    focus: pomodoroModel.focusDuration,
                    breakDuration: pomodoroModel.breakDuration
                )
                HapticsManager.shared.impact(.light)
            }
        }
        state.onToggleShrink = { RootState.shared.toggleShrink() }
        state.onEscape = { _ = RootState.shared.handleEscape() }

        monitor.onPageLeft = { RootState.shared.goLeft() }
        monitor.onPageRight = { RootState.shared.goRight() }
        monitor.onGoToPage = { index in RootState.shared.go(to: index) }
        monitor.onToggleShrink = { RootState.shared.toggleShrink() }
        monitor.onTogglePlay = { RootState.shared.onPrimary?() }
        monitor.onReset = { RootState.shared.onReset?() }
        monitor.onEscape = { RootState.shared.handleEscape() }
        monitor.onFullscreen = { RootState.shared.toggleFullscreen() }
        monitor.start()

        // 启动后短暂提示一次快捷键。
        state.revealHints()
    }

    // MARK: - Backdrop

    /// 纯黑底：光晕与暗角分别叠加在页面上。
    private var backdrop: some View {
        Color.black
            .ignoresSafeArea()
    }

    /// 极淡中心光晕（中心偏上），让大面积纯黑不死板。
    private var ambientGlow: some View {
        RadialGradient(
            colors: [Color.white.opacity(0.035), Color.white.opacity(0)],
            center: UnitPoint(x: 0.5, y: 0.34),
            startRadius: 0,
            endRadius: 560
        )
        .ignoresSafeArea()
    }

    /// 底部轻微压暗，形成极弱的 vignette。
    private var vignette: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.58),
                .init(color: Color.black.opacity(0.26), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
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

    /// 可点击的页面指示器：当前页为胶囊，其余为圆点，悬停放大并显示手型光标。
    private var pageIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<state.pageCount, id: \.self) { index in
                PageDot(active: index == state.page) {
                    state.go(to: index)
                }
            }
        }
    }

    // MARK: - Hints

    private var hintsBar: some View {
        HintsBar()
            .padding(.leading, 18)
            .padding(.bottom, 38)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .opacity(hintsVisible ? 1 : 0)
            .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.4), value: hintsVisible)
            .allowsHitTesting(false)
    }

    private var hintsVisible: Bool {
        state.hintsVisible && !state.shrunk && !state.showEditor && !state.pomodoroEditing
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
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { state.showEditor.toggle() }
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
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { state.showEditor = false }
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

/// 单个页面指示点：22×22 点击热区，选中态为 14×5 胶囊，悬停略微放大。
private struct PageDot: View {
    let active: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(active ? 0.55 : 0.18))
                .frame(width: active ? 14 : 5, height: 5)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
                .scaleEffect(hovering ? 1.12 : 1)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            hovering = inside
            if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: active)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: hovering)
    }
}

/// 左下角极简快捷键提示：仅在启动后 / ⌘/ 后短暂出现。
private struct HintsBar: View {
    var body: some View {
        HStack(spacing: 7) {
            Keycap("← →")
            Text("切换")
            separator
            Keycap("空格")
            Text("开始/暂停")
            separator
            Keycap("R")
            Text("重置")
            separator
            Keycap("右键")
            Text("外观")
        }
        .font(.system(size: 10.5, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.28))
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.16))
    }
}

private struct Keycap: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
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
