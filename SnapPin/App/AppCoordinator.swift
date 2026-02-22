import AppKit
import ServiceManagement

/// アプリ全体の唯一の司令塔
/// 全コンポーネントを所有し、各 delegate を実装して処理を統括する
@MainActor
class AppCoordinator {
    
    // MARK: - Components
    
    private let statusBarController = StatusBarController()
    private let captureManager = CaptureManager()
    private let floatingWindowManager = FloatingWindowManager()
    private let overlayWindowController = CaptureAreaSelectController()
    
    // MARK: - Start
    
    func start() {
        statusBarController.delegate = self
        overlayWindowController.delegate = self
        
        statusBarController.setup()
        
        Task {
            await captureManager.requestPermission()
        }
    }
}

// MARK: - StatusBarControllerDelegate
@MainActor
extension AppCoordinator: StatusBarControllerDelegate {
    
    func statusBarDidRequestCapture() {
        overlayWindowController.show()
    }
    
    func statusBarDidDropImages(_ urls: [URL]) {
        urls.forEach { floatingWindowManager.showFromFile(url: $0) }
    }
    
    func statusBarDidToggleAutoLaunch() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("自動起動設定の変更に失敗: \(error)")
        }
    }
}

// MARK: - OverlayWindowControllerDelegate
@MainActor
extension AppCoordinator: CaptureAreaSelectControllerDelegate {
    
    func selectRect(_ rect: NSRect) {
        // オーバーレイが消えてから少し待ってキャプチャする（写り込み防止）
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Capture.overlayDismissDelay) { [weak self] in
            guard let self else { return }
            Task {
                do {
                    let image = try await self.captureManager.captureImage(rect: rect)
                    await MainActor.run {
                        self.floatingWindowManager.show(image: image, rect: rect)
                    }
                } catch {
                    print("キャプチャ失敗: \(error)")
                }
            }
        }
    }
    
    func cancel() {
        // キャンセル時は何もしない（OverlayWindowController がオーバーレイを閉じ済み）
    }
}
