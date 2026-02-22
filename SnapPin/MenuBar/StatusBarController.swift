import AppKit
import ServiceManagement

// MARK: - Delegate Protocol
@MainActor
protocol StatusBarControllerDelegate: AnyObject {
    func statusBarDidRequestCapture()
    func statusBarDidDropImages(_ urls: [URL])
    func statusBarDidToggleAutoLaunch()
}

// MARK: - Controller

/// NSStatusItem（メニューバーアイコン）の管理・左クリック/右クリック/D&D の検知を担う
/// ビジネスロジックは持たず、イベントを delegate に通知するだけ
@MainActor
class StatusBarController {
    
    weak var delegate: StatusBarControllerDelegate?
    
    private var statusItem: NSStatusItem?
    private var draggableView: DraggableStatusView?
    
    // MARK: - Setup
    
    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        
        guard let button = item.button else { return }
        button.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "SnapPin")
        button.action = #selector(iconClicked)
        button.target = self
        // 左クリック・右クリックの両方でアクションを受け取る
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        // ステータスバーボタンの上に透明な DraggableStatusView を重ねて D&D を受け付ける
        let view = DraggableStatusView(frame: button.bounds)
        view.autoresizingMask = [.width, .height]
        // D&D コールバックを delegate に橋渡しする
        view.onImageDropped = { [weak self] urls in
            self?.delegate?.statusBarDidDropImages(urls)
        }
        button.addSubview(view)
        draggableView = view
    }
    
    // MARK: - Actions
    
    @objc private func iconClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .leftMouseDown {
            delegate?.statusBarDidRequestCapture()
        } else if event.type == .rightMouseDown {
            showSettingsMenu()
        }
    }
    
    private func showSettingsMenu() {
        let menu = NSMenu()
        
        let isEnabled = SMAppService.mainApp.status == .enabled
        let autoLaunchItem = NSMenuItem(
            title: "ログイン時に起動",
            action: #selector(toggleAutoLaunch),
            keyEquivalent: ""
        )
        autoLaunchItem.target = self
        autoLaunchItem.state = isEnabled ? .on : .off
        menu.addItem(autoLaunchItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        // menu をセットしてから performClick するとシステムがメニューを表示する
        // その後 nil に戻さないと次の左クリックでもメニューが開いてしまう
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func toggleAutoLaunch() {
        delegate?.statusBarDidToggleAutoLaunch()
    }
}
