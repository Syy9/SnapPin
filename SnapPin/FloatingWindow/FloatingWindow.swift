import AppKit
class FloatingWindow: NSWindow {
    
    init(image: CGImage, rect: NSRect) {
        super.init(
            contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false
        )
        
        self.isReleasedWhenClosed = false
        // 常に他のウィンドウより手前に表示する
        self.level = .floating
        // 背景を透明にする（isOpaque=falseにしないとbackgroundColorが効かない）
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        // タイトルバーがないウィンドウをドラッグ移動できるようにする
        self.isMovableByWindowBackground = true
        
        let contentView = FloatingContentView(frame: NSRect(origin: .zero, size: rect.size), image: image)
        self.contentView = contentView
        
    }
    
    // borderlessウィンドウはデフォルトでキーウィンドウになれないのでオーバーライドする
    override var canBecomeKey: Bool { true }
    
    
    // ダブルクリックでウィンドウを閉じる
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            self.close()
        }
    }
    
    // 右クリックでメニューを表示する
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "閉じる", action: #selector(closeWindow), keyEquivalent: ""))
        // targetをselfにしないとアクションが呼ばれない
        menu.items.forEach { $0.target = self }
        menu.popUp(positioning: nil, at: event.locationInWindow, in: self.contentView)
    }
    
    @objc func closeWindow() {
        self.close()
    }
    
    // Escキーでウィンドウを閉じる
    override func keyDown(with event: NSEvent) {
        // keyCode 53 = Escキー
        if event.keyCode == 53 {
            self.close()
        } else {
            super.keyDown(with: event)
        }
    }
}

private class FloatingContentView: NSView {
    
    init(frame frameRect: NSRect, image: CGImage) {
        super.init(frame: frameRect)
        
        // CALayerを有効にする（wantsLayer=trueにするとlayerプロパティが使えるようになる）
        wantsLayer = true
        
        // NSImageView経由ではなくCALayerのcontentsに直接CGImageをセットする
        // これによりCore AnimationがRetinaスケールを自動処理してぼやけを防ぐ
        layer?.contents = image
        
        // layerのサイズに合わせて画像をリサイズして表示する
        layer?.contentsGravity = .resize
        
        // Retinaスケールをlayerに伝える（これがないと2x画像が2倍サイズで表示される）
        layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        
        layer?.borderWidth = Constants.FloatingWindow.borderWidth
        layer?.borderColor = Constants.FloatingWindow.borderColor.cgColor
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // スクロールでウィンドウの透明度を変える
    override func scrollWheel(with event: NSEvent) {
        guard let window = self.window else { return }
        let delta = event.deltaY * Constants.FloatingWindow.scrollAlphaDelta
        let newAlpha = min(
            Constants.FloatingWindow.maxAlpha,
            max(Constants.FloatingWindow.minAlpha, window.alphaValue + delta)
        )
        window.alphaValue = newAlpha
    }
}
