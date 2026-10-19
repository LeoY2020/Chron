import AppKit

/// 窗口外观：沉浸式暗色、隐藏标题、统一透明标题栏、最小尺寸。
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        DispatchQueue.main.async { self.configureAllWindows() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        configureAllWindows()
    }

    private func configureAllWindows() {
        for window in NSApp.windows {
            configure(window)
        }
    }

    private func configure(_ window: NSWindow) {
        window.title = "Chron"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .black
        window.isOpaque = true
        window.minSize = NSSize(width: 480, height: 360)
    }
}