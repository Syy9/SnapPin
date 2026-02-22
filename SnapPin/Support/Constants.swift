import Foundation
import AppKit

enum Constants {
    enum FloatingWindow {
        /// ウィンドウ境界線の太さ
        static let borderWidth: CGFloat = 1.0
        /// ウィンドウ境界線の色
        static let borderColor: NSColor = .black.withAlphaComponent(0.8)
        /// 透明度の最小値
        static let minAlpha: CGFloat = 0.1
        /// 透明度の最大値
        static let maxAlpha: CGFloat = 1.0
        /// スクロール1ノッチあたりの透明度変化量
        static let scrollAlphaDelta: CGFloat = 0.05
    }
    
    enum Selection {
        /// この幅/高さ未満の選択はキャンセル扱い
        static let minimumSize: CGFloat = 10
    }
    
    enum Capture {
        /// オーバーレイ非表示→キャプチャ開始までの待機時間（秒）
        static let overlayDismissDelay: TimeInterval = 0.1
    }
}
