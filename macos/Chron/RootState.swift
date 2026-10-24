import SwiftUI
import AppKit

/// 分页 / 收缩等交互状态。放在引用类型中，便于输入监听闭包始终读取最新值。
final class RootState: ObservableObject {
    /// 单例：菜单命令（.commands）无法直接拿到视图内的 StateObject，统一从这里触达。
    static let shared = RootState()

    @Published var page = 0
    @Published var shrunk = false
    @Published var showEditor = false
    @Published var pomodoroEditing = false
    @Published var dragOffset: CGFloat = 0
    /// 左下角快捷键提示的可见性（启动后 / ⌘/ 后短暂显示）。
    @Published var hintsVisible = false

    let pageCount = 3

    /// 由 RootView 在 configure() 中注入，避免菜单命令直接依赖具体计时模型。
    var onPrimary: (() -> Void)?
    var onReset: (() -> Void)?
    var onToggleShrink: (() -> Void)?
    var onEscape: (() -> Void)?

    private var hintDismiss: DispatchWorkItem?

    /// 收缩 / 编辑态下禁用分页。
    private var locked: Bool { shrunk || showEditor || pomodoroEditing }

    private init() {}

    func goLeft() {
        go(to: page - 1)
    }

    func goRight() {
        go(to: page + 1)
    }

    /// 直接跳到指定页；收缩 / 编辑态与越界时忽略。
    func go(to target: Int) {
        guard !locked, target != page, target >= 0, target < pageCount else { return }
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { page = target }
        HapticsManager.shared.impact(.light)
    }

    /// 长按 / 右键：进入或退出收缩 + 样式栏状态。番茄钟页不参与。
    func toggleShrink() {
        guard page != 1 else { return }
        HapticsManager.shared.impact(.medium)
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) {
            shrunk.toggle()
            if !shrunk { showEditor = false }
        }
    }

    func exitEditor() {
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { showEditor = false }
    }

    /// Esc 分级退出：就地编辑器 → 设置态 → 无操作。返回是否消费了这次按键。
    @discardableResult
    func handleEscape() -> Bool {
        if showEditor {
            exitEditor()
        } else if pomodoroEditing {
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.3)) { pomodoroEditing = false }
        } else if shrunk {
            toggleShrink()
        } else {
            return false
        }
        return true
    }

    /// 显示快捷键提示，并在 8 秒后淡出。
    func revealHints() {
        hintDismiss?.cancel()
        hintsVisible = true
        let item = DispatchWorkItem { [weak self] in
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.4)) {
                self?.hintsVisible = false
            }
        }
        hintDismiss = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: item)
    }

    /// 切换当前窗口全屏；焦点在文本输入时忽略，避免误触。
    func toggleFullscreen() {
        guard let window = NSApp.keyWindow else { return }
        if let responder = window.firstResponder, responder is NSTextView { return }
        window.toggleFullScreen(nil)
    }
}
