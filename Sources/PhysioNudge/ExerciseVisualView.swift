import AppKit

/// Schematic exercise sketch: head + shoulders plus a movement arrow
/// (nod = up/down, shake = left/right, tilt = ear to shoulder).
/// Light, restrained animation to guide the movement.
final class ExerciseVisualView: NSView {
    enum Kind: String {
        case none
        case nod
        case shake
        case tilt
    }

    private var kind: Kind = .none
    private var phase: CGFloat = 0
    private var timer: Timer?

    override var isFlipped: Bool { false }

    func configure(kind: Kind) {
        self.kind = kind
        needsDisplay = true
    }

    func startAnimating() {
        timer?.invalidate()
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        phase = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.phase += 0.10
            self.needsDisplay = true
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        let w = bounds.width
        let h = bounds.height
        let cx = bounds.midX

        let bodyColor = NSColor.labelColor
        let arrowColor = NSColor.systemBlue

        // Shoulders
        let shoulderWidth = w * 0.70
        let shoulderTop = h * 0.16
        bodyColor.set()
        let shoulders = NSBezierPath()
        shoulders.appendArc(withCenter: NSPoint(x: cx, y: shoulderTop),
                            radius: shoulderWidth / 2,
                            startAngle: 15, endAngle: 165)
        shoulders.lineWidth = 7
        shoulders.lineCapStyle = .round
        shoulders.stroke()

        // Neck + head, offset by the movement
        let swing = sin(phase) * w * 0.035
        var headCenter = NSPoint(x: cx, y: h * 0.58)
        var neckTop = NSPoint(x: cx, y: shoulderTop + h * 0.02)
        switch kind {
        case .nod:
            headCenter.y += swing
        case .shake:
            headCenter.x += swing
            neckTop.x += swing * 0.7
        case .tilt:
            headCenter.x += swing
            headCenter.y -= abs(swing) * 0.25
            neckTop.x += swing * 0.5
        case .none:
            break
        }

        let neck = NSBezierPath()
        neck.move(to: neckTop)
        neck.line(to: NSPoint(x: headCenter.x, y: headCenter.y - h * 0.13))
        neck.lineWidth = 9
        neck.lineCapStyle = .round
        neck.stroke()

        let headRadius = w * 0.15
        let head = NSBezierPath(ovalIn: NSRect(x: headCenter.x - headRadius,
                                                y: headCenter.y - headRadius,
                                                width: headRadius * 2,
                                                height: headRadius * 2))
        head.lineWidth = 4.5
        head.stroke()

        // Movement arrow
        arrowColor.set()
        switch kind {
        case .nod:
            let x = cx + w * 0.30
            drawArrow(from: NSPoint(x: x, y: h * 0.48),
                      to: NSPoint(x: x, y: h * 0.68),
                      doubleHeaded: true)
        case .shake:
            drawArrow(from: NSPoint(x: cx - w * 0.22, y: h * 0.86),
                      to: NSPoint(x: cx + w * 0.22, y: h * 0.86),
                      doubleHeaded: true)
        case .tilt:
            let start = NSPoint(x: headCenter.x + headRadius * 0.6,
                                y: headCenter.y + headRadius * 0.8)
            let end = NSPoint(x: cx + shoulderWidth * 0.42,
                              y: shoulderTop + h * 0.06)
            let control = NSPoint(x: cx + w * 0.30, y: h * 0.80)
            let curve = NSBezierPath()
            curve.move(to: start)
            curve.curve(to: end, controlPoint1: control, controlPoint2: end)
            curve.lineWidth = 3
            curve.lineCapStyle = .round
            curve.stroke()
            drawArrowhead(at: end, pointingToward: NSPoint(x: control.x, y: control.y))
        case .none:
            break
        }
    }

    private func drawArrow(from start: NSPoint, to end: NSPoint, doubleHeaded: Bool) {
        let line = NSBezierPath()
        line.move(to: start)
        line.line(to: end)
        line.lineWidth = 3
        line.lineCapStyle = .round
        line.stroke()
        drawArrowhead(at: end, pointingToward: start)
        if doubleHeaded {
            drawArrowhead(at: start, pointingToward: end)
        }
    }

    private func drawArrowhead(at tip: NSPoint, pointingToward origin: NSPoint) {
        let angle = atan2(origin.y - tip.y, origin.x - tip.x)
        let length: CGFloat = 8
        let path = NSBezierPath()
        path.move(to: tip)
        path.line(to: NSPoint(x: tip.x + cos(angle - 0.4) * length,
                              y: tip.y + sin(angle - 0.4) * length))
        path.line(to: NSPoint(x: tip.x + cos(angle + 0.4) * length,
                              y: tip.y + sin(angle + 0.4) * length))
        path.closePath()
        path.fill()
    }
}
