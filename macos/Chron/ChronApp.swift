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
        }
    }
}