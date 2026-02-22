import AppKit

@MainActor
protocol CaptureAreaSelectWindowInternalDelegate: AnyObject {
    func selectRect(_ window: CaptureAreaSelectWindow, didSelectRect rect: NSRect)
    func cancel(_ window: CaptureAreaSelectWindow)
}

@MainActor
class CaptureAreaSelectWindow: NSWindow {
    let selectionView: SelectionView
    
    weak var internalDelegate: CaptureAreaSelectWindowInternalDelegate?
    
    init(_ screen: NSScreen) {
        selectionView = SelectionView(frame: screen.frame)
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.level = .screenSaver
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        
        selectionView.onSelectionCompleted = { [weak self] rect in
            guard let self = self else { return }
            self.internalDelegate?.selectRect(self, didSelectRect: rect)
        }
        
        selectionView.onSelectionCancelled = { [weak self] in
            guard let self = self else { return }
            self.internalDelegate?.cancel(self)
        }
        
        self.contentView = selectionView
    }
    
    override var canBecomeKey: Bool { true }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            self.internalDelegate?.cancel(self)
        }
    }
}
