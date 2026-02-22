import AppKit

// MARK: - Delegate Protocol
@MainActor
protocol CaptureAreaSelectControllerDelegate: AnyObject {
    func selectRect(_ rect: NSRect)
    func cancel()
}

// MARK: - Controller

/// 全画面オーバーレイの表示・非表示と SelectionView のイベントを管理する
@MainActor
class CaptureAreaSelectController {
    
    weak var delegate: CaptureAreaSelectControllerDelegate?
    
    private var overlayWindow: CaptureAreaSelectWindow?
    
    // MARK: - Show / Hide
    
    func show() {
        guard let screen = NSScreen.main else { return }
        
        let window = CaptureAreaSelectWindow(screen)
        overlayWindow = window
        overlayWindow?.internalDelegate = self
        
        window.makeKeyAndOrderFront(nil)
        // オーバーレイがキーイベントを受け取れるようにアクティブ化する
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
extension CaptureAreaSelectController: CaptureAreaSelectWindowInternalDelegate {
    func selectRect(_ window: CaptureAreaSelectWindow, didSelectRect rect: NSRect) {
        self.overlayWindow?.close()
        self.delegate?.selectRect(rect)
    }
    
    func cancel(_ window: CaptureAreaSelectWindow) {
        self.overlayWindow?.close()
        self.delegate?.cancel()
    }
}
