import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let coordinator = AppCoordinator()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock アイコンを非表示にしてメニューバーアプリとして動作させる
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()
    }
}
