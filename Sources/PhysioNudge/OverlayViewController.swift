import AppKit

/// Spielt eine Übung ab: Titel, Anleitungstext und 1-3 GIFs in Sequenz.
/// Nach dem letzten GIF wird onFinish aufgerufen (Overlay blendet sich aus).
final class OverlayViewController: NSViewController {
    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let captionLabel = NSTextField(wrappingLabelWithString: "")
    private let imageView = NSImageView()

    private var animator: GifAnimator?
    private var playbackTimer: Timer?
    private var gifQueue: [URL] = []
    private var onFinish: (() -> Void)?

    override func loadView() {
        // UX-Spec 04: hudWindow-Material, Radius 16, Fade-in/out.
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16

        imageView.imageScaling = .scaleProportionallyUpOrDown

        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white

        captionLabel.font = NSFont.systemFont(ofSize: 12)
        captionLabel.textColor = .lightGray
        captionLabel.preferredMaxLayoutWidth = 260
        captionLabel.alignment = .center

        let stack = NSStackView(views: [imageView, titleLabel, captionLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: effectView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: effectView.bottomAnchor, constant: -16),
        ])

        view = effectView
    }

    func play(exercise: Exercise, directory: URL, perGifSeconds: Double, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        titleLabel.stringValue = exercise.title
        captionLabel.stringValue = exercise.caption
        gifQueue = exercise.gifs.map { directory.appendingPathComponent($0) }

        if gifQueue.isEmpty {
            // Fallback ohne GIFs: nur Text anzeigen, dann ausblenden.
            imageView.image = NSImage(systemSymbolName: "figure.flexibility",
                                      accessibilityDescription: nil)
            playbackTimer = Timer.scheduledTimer(withTimeInterval: perGifSeconds, repeats: false) { [weak self] _ in
                self?.onFinish?()
            }
            return
        }
        playNextGif(perGifSeconds: perGifSeconds)
    }

    private func playNextGif(perGifSeconds: Double) {
        playbackTimer?.invalidate()
        animator?.stop()
        animator = nil

        guard !gifQueue.isEmpty else {
            onFinish?()
            return
        }

        let url = gifQueue.removeFirst()
        if let nextAnimator = GifAnimator(url: url) {
            animator = nextAnimator
            nextAnimator.start(in: imageView)
        } else {
            // NFR-08: defektes GIF -> Icon statt Absturz.
            imageView.image = NSImage(systemSymbolName: "figure.flexibility",
                                      accessibilityDescription: nil)
        }

        playbackTimer = Timer.scheduledTimer(withTimeInterval: perGifSeconds, repeats: false) { [weak self] _ in
            self?.playNextGif(perGifSeconds: perGifSeconds)
        }
    }

    func stop() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        animator?.stop()
        animator = nil
    }
}
