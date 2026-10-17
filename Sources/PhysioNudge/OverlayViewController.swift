import AppKit

/// Presents a sequence of overlay items: title + amount, one after
/// another, then the "All done?" confirmation. Auto start with countdown;
/// "No" dismisses at any time.
final class OverlayViewController: NSViewController {
    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let progressLabel = NSTextField(labelWithString: "")
    private let imageView = NSImageView()
    private let noButton = NSButton(title: "No", target: nil, action: nil)
    private let yesButton = NSButton(title: "Yes", target: nil, action: nil)
    private let buttonStack = NSStackView()

    private var playbackTimer: Timer?
    private var countdownTimer: Timer?
    private var onCompletion: ((Bool) -> Void)?

    private var headerText = ""
    private var remainingItems: [OverlayItem] = []
    private var countdownSeconds = 10

    override func loadView() {
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = NSImage(systemSymbolName: "figure.flexibility",
                                  accessibilityDescription: nil)
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        progressLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        progressLabel.textColor = .lightGray
        progressLabel.alignment = .center

        noButton.bezelStyle = .rounded
        noButton.action = #selector(noClicked)
        yesButton.bezelStyle = .rounded
        yesButton.action = #selector(yesClicked)
        yesButton.isHidden = true

        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.addView(noButton, in: .trailing)

        let stack = NSStackView(views: [imageView, titleLabel, progressLabel, buttonStack])
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

    /// Present a sequence. `completion(true)` = user confirmed done,
    /// `completion(false)` = dismissed without confirmation.
    func present(header: String,
                 items: [OverlayItem],
                 autoDelaySeconds: Int,
                 completion: @escaping (Bool) -> Void) {
        headerText = header
        remainingItems = items
        onCompletion = completion
        countdownSeconds = max(0, min(60, autoDelaySeconds))

        titleLabel.stringValue = header
        progressLabel.stringValue = ""
        yesButton.isHidden = true
        startCountdown()
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        if countdownSeconds == 0 {
            beginSequence()
            return
        }
        progressLabel.stringValue = "Starting in \(countdownSeconds) s…"
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.countdownSeconds -= 1
            if self.countdownSeconds <= 0 {
                timer.invalidate()
                self.beginSequence()
            } else {
                self.progressLabel.stringValue = "Starting in \(self.countdownSeconds) s…"
            }
        }
    }

    @objc private func noClicked() {
        stop()
        onCompletion?(false)
    }

    @objc private func yesClicked() {
        stop()
        onCompletion?(true)
    }

    private func beginSequence() {
        playNext()
    }

    private func playNext() {
        guard !remainingItems.isEmpty else {
            showAllDone()
            return
        }
        let item = remainingItems.removeFirst()
        titleLabel.stringValue = item.title
        if let reps = item.reps {
            progressLabel.stringValue = "\(reps)x"
        } else {
            progressLabel.stringValue = "\(item.seconds ?? 0) s"
        }

        // Duration: seconds if given, otherwise estimate ~1.5 s per rep.
        let duration: TimeInterval
        if let seconds = item.seconds, seconds > 0 {
            duration = TimeInterval(seconds)
        } else {
            duration = TimeInterval(max(1, item.reps ?? 10)) * 1.5
        }
        playbackTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.playNext()
        }
    }

    private func showAllDone() {
        imageView.image = NSImage(systemSymbolName: "checkmark.circle",
                                   accessibilityDescription: nil)
        titleLabel.stringValue = headerText
        progressLabel.stringValue = ""
        buttonStack.views.forEach { buttonStack.removeView($0) }
        yesButton.isHidden = false
        buttonStack.addView(yesButton, in: .leading)
        buttonStack.addView(noButton, in: .trailing)
    }

    func stop() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}
