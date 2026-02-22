import AppKit

// メニューバーボタンの上に重ねる透明なView
// NSStatusBarButtonはD&Dを受け付けないため、このViewを重ねてD&Dを実現する
class DraggableStatusView: NSView {
    
    // ドロップされた画像URLをAppDelegateに通知するコールバック
    var onImageDropped: (([URL]) -> Void)?
    
    // コードで生成する場合はinitで登録する（awakeFromNibはXIB/Storyboard経由でないと呼ばれない）
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // ファイルURLのドラッグを受け付けるように登録する
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }
    
    // ドラッグがView上に入ったとき：受け入れ可能かどうかを返す
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 画像ファイルが含まれていれば.copy（+カーソル）を返す
        return imageURLs(from: sender).isEmpty ? [] : .copy
    }
    
    // ドラッグ中（移動するたびに呼ばれる）：引き続き受け入れ可能かどうかを返す
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return imageURLs(from: sender).isEmpty ? [] : .copy
    }
    
    // ドロップ直前：trueを返すとperformDragOperationが呼ばれる
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    // 実際にドロップされたとき：画像URLを取り出してコールバックを呼ぶ
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = imageURLs(from: sender)
        guard !urls.isEmpty else { return false }
        onImageDropped?(urls)
        return true
    }
    
    // ドラッグ情報から画像ファイルのURLだけを取り出すヘルパー
    private func imageURLs(from sender: NSDraggingInfo) -> [URL] {
        // ペーストボードからファイルURLだけを取得する（それ以外は無視）
        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else {
            return []
        }
        
        // 対応する画像拡張子のみにフィルタリングする
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff"]
        return urls.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
    }
}
