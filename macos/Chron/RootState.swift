import SwiftUI

/// 分页 / 收缩等交互状态。放在引用类型中，便于输入监听闭包始终读取最新值。
final class RootState: ObservableObject {
    @Published var page = 0
    @Published var shrunk = false
    @Published var showEditor = false
    @Published var pomodoroEditing = false
    @Published var dragOffset: CGFloat = 0

    let pageCount = 3

    /// 收缩 / 编辑态下禁用分页。
    private var locked: Bool { shrunk || showEditor || pomodoroEditing }

    func goLeft() {
        guard !locked, page > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page -= 1 }
        HapticsManager.shared.impact(.light)
    }

    func goRight() {
        guard !locked, page < pageCount - 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
        HapticsManager.shared.impact(.light)
    }

    /// 长按 / 右键：进入或退出收缩 + 样式栏状态。番茄钟页不参与。
    func toggleShrink() {
        guard page != 1 else { return }
        HapticsManager.shared.impact(.medium)
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            shrunk.toggle()
            if !shrunk { showEditor = false }
        }
    }

    func exitEditor() {
        withAnimation(.easeInOut(duration: 0.25)) { showEditor = false }
    }
}