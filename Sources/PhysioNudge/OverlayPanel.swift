import AppKit

enum OverlayCorner: String, CaseIterable {
    case bottomRight = "Bottom right"
    case bottomLeft = "Bottom left"
    case topRight = "Top right"
    case topLeft = "Top left"

    var storageKey: String {
        switch self {
        case .bottomRight: return "bottomRight"
        case .bottomLeft: return "bottomLeft"
        case .topRight: return "topRight"
        case .topLeft: return "topLeft"
        }
    }

    /// Anchor point of the panel in *screen* coordinates (bottom-left origin).
    func origin(for panelSize: NSSize, in screen: NSScreen, margin: CGFloat = 24) -> NSPoint {
        let visible = screen.visibleFrame
        switch self {
        case .bottomRight:
            return NSPoint(x: visible.maxX - panelSize.width - margin,
                           y: visible.minY + margin)
        case .bottomLeft:
            return NSPoint(x: visible.minX + margin,
                           y: visible.minY + margin)
        case .topRight:
            return NSPoint(x: visible.maxX - panelSize.width - margin,
                           y: visible.maxY - panelSize.height - margin)
        case .topLeft:
            return NSPoint(x: visible.minX + margin,
                           y: visible.maxY - panelSize.height - margin)
        }
    }
}

/// The overlay: an NSPanel that steals no focus on display and stays
/// visible above full-screen apps (requirements/04-overlay-ux-spec.md).
final class OverlayPanel: NSPanel {
    private var corner: OverlayCorner = .bottomRight
    private var overlaySize: NSSize = NSSize(width: 300, height: 300)

    convenience init(size: NSSize, corner: OverlayCorner) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let rect = NSRect(origin: corner.origin(for: size, in: screen), size: size)
        self.init(contentRect: rect,
                  styleMask: [.borderless, .nonactivatingPanel],
                  backing: .buffered,
                  defer: false)
        self.corner = corner
        self.overlaySize = size
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func setContentSize(_ newSize: NSSize) {
        super.setContentSize(newSize)
        overlaySize = newSize
        reposition()
    }

    /// Recompute the frame from the corner anchor — must be called after
    /// the content view controller changed the window's frame (AppKit
    /// resizes from the bottom-left origin otherwise, so a bottom-anchored
    /// panel would float and a top-anchored one would grow off-screen).
    func reposition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let origin = corner.origin(for: overlaySize, in: screen)
        let frame = NSRect(origin: origin, size: overlaySize)
        setFrame(frame, display: true)
    }

    func present(at corner: OverlayCorner) {
        self.corner = corner
        reposition()
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            self.animator().alphaValue = 1
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }
}
