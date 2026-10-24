import AppKit
import Combine

/// 桌面输入监听：键盘（←/→、空格、⌘1/2/3、R、Esc、F）、触控板双指横扫、右键。
/// 通过本地事件监视器实现，闭包由 RootView 注入，读取 RootState 引用类型以保持最新。
final class InputMonitor: ObservableObject {
    var onPageLeft: (() -> Void)?
    var onPageRight: (() -> Void)?
    var onGoToPage: ((Int) -> Void)?
    var onTogglePlay: (() -> Void)?
    var onToggleShrink: (() -> Void)?
    var onReset: (() -> Void)?
    /// 返回 true 表示消费了 Esc；未消费时放行给系统（例如退出全屏）。
    var onEscape: (() -> Bool)?
    var onFullscreen: (() -> Void)?

    private var monitors: [Any] = []
    private var swipeAccum: CGFloat = 0

    func start() {
        guard monitors.isEmpty else { return }

        if let key = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            guard let self else { return event }
            // 文本输入时把按键原样交回，避免吞掉空格 / R / F 等字符。
            if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView {
                return event
            }
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let plain = !mods.contains(.command) && !mods.contains(.option) && !mods.contains(.control)
            switch event.keyCode {
            case 123: self.onPageLeft?(); return nil   // ←
            case 124: self.onPageRight?(); return nil  // →
            case 49:                                    // space
                if plain { self.onTogglePlay?(); return nil }
            case 18:                                    // ⌘1
                if mods.contains(.command) { self.onGoToPage?(0); return nil }
            case 19:                                    // ⌘2
                if mods.contains(.command) { self.onGoToPage?(1); return nil }
            case 20:                                    // ⌘3
                if mods.contains(.command) { self.onGoToPage?(2); return nil }
            case 15:                                    // R
                if plain { self.onReset?(); return nil }
            case 53:                                    // Esc
                if plain, self.onEscape?() == true { return nil }
            case 3:                                     // F
                if plain { self.onFullscreen?(); return nil }
            default:
                return event
            }
            return event
        }) {
            monitors.append(key)
        }

        if let scroll = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: { [weak self] event in
            guard let self else { return event }
            let dx = event.scrollingDeltaX
            let dy = event.scrollingDeltaY
            // 仅拦截以横向为主的滑动；纵向滚动（时长滚轮 / 原生控件）原样放行。
            guard abs(dx) > abs(dy), abs(dx) > 0.5 else {
                self.swipeAccum = 0
                return event
            }
            if event.momentumPhase.isEmpty {
                self.swipeAccum += dx
                if self.swipeAccum <= -46 {
                    self.swipeAccum = 0
                    self.onPageRight?()
                } else if self.swipeAccum >= 46 {
                    self.swipeAccum = 0
                    self.onPageLeft?()
                }
            }
            return nil
        }) {
            monitors.append(scroll)
        }

        if let swipe = NSEvent.addLocalMonitorForEvents(matching: .swipe, handler: { [weak self] event in
            guard let self else { return event }
            if event.deltaX > 0 { self.onPageLeft?() }
            else if event.deltaX < 0 { self.onPageRight?() }
            return event
        }) {
            monitors.append(swipe)
        }

        if let right = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown, handler: { [weak self] event in
            // 设置态下右键等同于关闭；非设置态则进入收缩 + 样式栏。
            self?.onToggleShrink?()
            return nil
        }) {
            monitors.append(right)
        }
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }
}
