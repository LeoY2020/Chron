import SwiftUI

@main
struct ChronApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentMinSize)
        .commands {
            // 单一全屏时钟窗口：移除"新建"等无关菜单项。
            CommandGroup(replacing: .newItem) {}

            // 计时：全局动作由 RootState 单例转发，供菜单栏发现快捷键。
            CommandMenu("计时") {
                Button("开始 / 暂停") {
                    RootState.shared.onPrimary?()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("重置") {
                    RootState.shared.onReset?()
                }
                .keyboardShortcut("r", modifiers: [])
            }

            // 显示：分页、直达页面、全屏与快捷键提示。
            CommandMenu("显示") {
                Button("上一页") {
                    RootState.shared.goLeft()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)

                Button("下一页") {
                    RootState.shared.goRight()
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)

                Divider()

                Button("倒计时") {
                    RootState.shared.go(to: 0)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("番茄钟") {
                    RootState.shared.go(to: 1)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("时钟") {
                    RootState.shared.go(to: 2)
                }
                .keyboardShortcut("3", modifiers: .command)

                Divider()

                Button("切换全屏") {
                    RootState.shared.toggleFullscreen()
                }
                .keyboardShortcut("f", modifiers: [])

                Button("显示快捷键") {
                    RootState.shared.revealHints()
                }
                .keyboardShortcut("/", modifiers: .command)
            }
        }
    }
}