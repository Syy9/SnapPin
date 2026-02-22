import AppKit

/// FloatingWindow の生成・配列管理を担う
/// NSWindowDelegate を実装して閉じられたウィンドウを配列から自動除去する
class FloatingWindowManager: NSObject {
    
    private var windows: [FloatingWindow] = []
    
    // MARK: - Show from CGImage (キャプチャ結果を表示)
    
    func show(image: CGImage, rect: NSRect) {
        let window = FloatingWindow(image: image, rect: rect)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }
    
    // MARK: - Show from file URL (D&D で渡されたファイルを表示)
    
    func showFromFile(url: URL) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("画像の読み込み失敗: \(url)")
            return
        }
        
        // Retina ディスプレイでは物理ピクセル数を backingScaleFactor で割って論理サイズにする
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        let logicalSize = NSSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        
        // 画面中央に配置する
        let screenFrame = NSScreen.main?.frame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - logicalSize.width / 2,
            y: screenFrame.midY - logicalSize.height / 2
        )
        
        show(image: cgImage, rect: NSRect(origin: origin, size: logicalSize))
    }
}

// MARK: - NSWindowDelegate

extension FloatingWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closed = notification.object as? FloatingWindow else { return }
        windows.removeAll { $0 === closed }
    }
}
