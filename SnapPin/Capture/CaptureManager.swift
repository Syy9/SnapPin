import AppKit
import ScreenCaptureKit

/// SCScreenshotManager の詳細を隠蔽し、NSRect → CGImage の変換を担う
@MainActor
class CaptureManager {
    
    // MARK: - Permission
    
    /// 画面収録権限のリクエスト（初回起動時に許可ダイアログが出る）
    func requestPermission() async {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            print("画面収録権限：許可済み")
        } catch {
            print("画面収録権限：未許可 \(error)")
        }
    }
    
    // MARK: - Capture
    
    /// 指定した NSRect（左下原点）の領域をキャプチャして CGImage を返す
    func captureImage(rect: NSRect) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            throw CaptureError.displayNotFound
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // アンチエイリアスを防ぐために整数に丸める
        let roundedRect = NSRect(
            x: floor(rect.origin.x),
            y: floor(rect.origin.y),
            width: ceil(rect.width),
            height: ceil(rect.height)
        )
        
        // SCScreenshotManager は CG 座標系（左上原点）を使う
        // NSView は左下原点なので Y 軸を反転させる
        let screenHeight = display.height
        let cgRect = CGRect(
            x: roundedRect.origin.x,
            y: CGFloat(screenHeight) - roundedRect.origin.y - roundedRect.height,
            width: roundedRect.width,
            height: roundedRect.height
        )
        
        // Retina ディスプレイでは論理サイズ × backingScaleFactor が物理ピクセル数になる
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        let config = SCStreamConfiguration()
        config.sourceRect = cgRect
        config.width = Int(roundedRect.width * scale)
        config.height = Int(roundedRect.height * scale)
        config.colorSpaceName = CGColorSpace.sRGB
        
        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }
}

// MARK: - Errors

enum CaptureError: Error {
    case displayNotFound
}
