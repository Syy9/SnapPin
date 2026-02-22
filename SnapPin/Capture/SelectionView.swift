import AppKit

// オーバーレイ上でマウスドラッグによる矩形選択を行うView
class SelectionView: NSView {
    private var selectionRect: NSRect?
    private var startPoint: NSPoint?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // マウスボタンを押した瞬間に開始点を記録する
    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = nil
        needsDisplay = true
    }
    
    // ドラッグ中は現在位置と開始点から矩形を計算して描画する
    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        
        // min/maxで左上・右下の順序を正規化する（右→左ドラッグにも対応）
        selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }
    
    // マウスボタンを離したときに選択完了またはキャンセルを通知する
    override func mouseUp(with event: NSEvent) {
        guard let rect = selectionRect else {
            // ドラッグせずにクリックだけした場合はキャンセル扱い
            onSelectionCancelled?()
            return
        }
        
        // 極小選択はミス操作とみなしてキャンセル
        if rect.width < Constants.Selection.minimumSize || rect.height < Constants.Selection.minimumSize {
            onSelectionCancelled?()
            return
        }
        
        onSelectionCompleted?(rect)
    }
    
    // 選択範囲外を半透明の黒で塗りつぶし、選択範囲だけ「くり抜いて」明るく見せる
    override func draw(_ dirtyRect: NSRect) {
        guard let rect = selectionRect else {
            // 選択開始前は全面を半透明黒で塗る
            NSColor.black.withAlphaComponent(0.3).setFill()
            bounds.fill()
            return
        }
        
        // evenOddルール：外側パスと内側パスを合成し、重なり部分（選択範囲）を透明にする
        let fullPath = NSBezierPath(rect: bounds)
        let holePath = NSBezierPath(rect: rect)
        fullPath.append(holePath.reversed)
        fullPath.windingRule = .evenOdd
        
        NSColor.black.withAlphaComponent(0.3).setFill()
        fullPath.fill()
    }
    
    // オーバーレイが表示されている間はカスタムカーソルを使う
    // クロスヘア＋「ドラッグしてスクリーンショットを撮影」テキストを右下に表示する
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: Self.tooltipCursor)
    }
    
    // Assets.xcassetsに追加した画像からカーソルを生成する
    // hotSpotはクリック判定の基準点。画像内のクロスヘア中心 (16, 16) を指定する
    // （NSCursorのhotSpotは左上原点の座標系）
    private static let tooltipCursor: NSCursor = {
        let image = NSImage(named: "cursor_tooltip")!
        return NSCursor(image: image, hotSpot: NSPoint(x: 11, y: 11))
    }()
    
    // 選択完了時のコールバック（選択矩形をNSRectで渡す）
    var onSelectionCompleted: ((NSRect) -> Void)?
    // キャンセル時のコールバック
    var onSelectionCancelled: (() -> Void)?
}
