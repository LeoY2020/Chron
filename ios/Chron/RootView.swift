import SwiftUI

/// 根视图：三页全屏水平分页（Countdown / Pomodoro / Clock）。
/// 长按进入"收缩 + 底部样式栏"的原地设置状态，此时禁用分页手势。
struct RootView: View {
    @StateObject private var settings = ChronSettings.shared
    @StateObject private var persistence = PersistenceManager.shared
    @StateObject private var countdown: CountdownModel
    @StateObject private var pomodoro: PomodoroModel

    @State private var page = 0
    @State private var shrunk = false
    @State private var showEditor = false
    @State private var dragOffset: CGFloat = 0
    @State private var pomodoroEditing = false

    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int

    private let pageCount = 3

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
                    .scaleEffect(shrunk ? 0.92 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: shrunk ? 44 : 0, style: .continuous))
                    .animation(.spring(response: 0.36, dampingFraction: 0.82), value: shrunk)

                pageIndicator
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 14)
                    .opacity(shrunk ? 0 : 1)

                if shrunk && page != 1 {
                    bottomPanel
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.82), value: shrunk)
            .onAppear {
                HapticsManager.shared.prepare()
                countdown.onFinish = { HapticsManager.shared.impact(.heavy) }
                pomodoro.onPhaseComplete = { _ in HapticsManager.shared.impact(.heavy) }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pager

    private func pager(width: CGFloat) -> some View {
        ZStack {
            CountdownView(model: countdown, settings: settings, shrunk: shrunk)
                .frame(width: width)
                .offset(x: CGFloat(0 - page) * width + dragOffset)

            PomodoroView(model: pomodoro, settings: settings, persistence: persistence, editingTime: $pomodoroEditing)
                .frame(width: width)
                .offset(x: CGFloat(1 - page) * width + dragOffset)

            ClockView(settings: settings)
                .frame(width: width)
                .offset(x: CGFloat(2 - page) * width + dragOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .simultaneousGesture(pagerGesture(width: width))
        .onLongPressGesture(minimumDuration: 0.45) {
            toggleShrink()
        }
        .onTapGesture {
            if shrunk { toggleShrink() }
        }
    }

    private func pagerGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                if shrunk || showEditor || pomodoroEditing { return }
                let raw = value.translation.width
                if abs(value.translation.height) > abs(raw) { dragOffset = 0; return }
                let atStart = page == 0 && raw > 0
                let atEnd = page == 2 && raw < 0
                dragOffset = (atStart || atEnd) ? raw * 0.28 : raw
            }
            .onEnded { value in
                if shrunk || showEditor || pomodoroEditing { return }
                let raw = value.translation.width
                let predicted = value.predictedEndTranslation.width
                let signal = abs(predicted) > abs(raw) ? predicted : raw
                let threshold = width * 0.22
                let oldPage = page
                var target = page
                if signal < -threshold, page < pageCount - 1 {
                    target = page + 1
                } else if signal > threshold, page > 0 {
                    target = page - 1
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    page = target
                    dragOffset = 0
                }
                if target != oldPage {
                    HapticsManager.shared.impact(.light)
                }
            }
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index == page ? 0.55 : 0.18))
                    .frame(width: 5, height: 5)
            }
        }
    }

    // MARK: - Shrink / style panel

    private func toggleShrink() {
        guard page != 1 else { return }
        HapticsManager.shared.impact(.medium)
        if shrunk {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                shrunk = false
                showEditor = false
            }
        } else {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                shrunk = true
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            if showEditor {
                StyleEditorView(settings: settings, isCountdown: page == 0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            StyleBarView(chips: chips, selectedID: selectedID) { id in
                selectStyle(id)
            } onEdit: {
                withAnimation(.easeInOut(duration: 0.28)) { showEditor.toggle() }
            }

            if page == 0 && !countdown.isRunning {
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
        if page == 0 {
            return CountdownStyle.allCases.map {
                StyleChip(id: $0.rawValue, title: $0.title, symbol: $0.symbol)
            }
        }
        return ClockStyle.allCases.map {
            StyleChip(id: $0.rawValue, title: $0.title, symbol: $0.symbol)
        }
    }

    private var selectedID: String {
        page == 0 ? settings.countdownStyle.rawValue : settings.clockStyle.rawValue
    }

    private func selectStyle(_ id: String) {
        withAnimation(.easeInOut(duration: 0.25)) { showEditor = false }
        if page == 0, let style = CountdownStyle(rawValue: id) {
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


