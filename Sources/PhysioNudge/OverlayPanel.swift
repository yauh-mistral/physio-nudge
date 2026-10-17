import AppKit

enum OverlayCorner: String, CaseIterable {
    case bottomRight = "unten rechts"
    case bottomLeft = "unten links"
    case topRight = "oben rechts"
    case topLeft = "oben links"

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

/// Das Overlay: ein NSPanel, das beim Anzeigen KEINEN Fokus stiehlt und auch
/// über Fullscreen-Apps sichtbar bleibt (Anforderung 04-overlay-ux-spec.md).
final class OverlayPanel: NSPanel {
    init(size: NSSize, corner: OverlayCorner) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let rect = NSRect(origin: corner.origin(for: size, in: screen), size: size)
        super.init(contentRect: rect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func present() {
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
