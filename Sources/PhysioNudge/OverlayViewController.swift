import AppKit

/// Presents a sequence of overlay items: title + amount, one after
/// another, then the "All done?" confirmation.
/// Buttons are explicit: "Start Now" (skip the countdown), "Skip"
/// (dismiss without doing), and at the end "Done" / "Skipped".
final class OverlayViewController: NSViewController {
    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let descriptionLabel = NSTextField(wrappingLabelWithString: "")
    private let progressLabel = NSTextField(labelWithString: "")
    private let visualView = ExerciseVisualView()
    private let imageView = NSImageView()
    private let startNowButton = NSButton(title: "Start Now", target: nil, action: nil)
    private let skipButton = NSButton(title: "Skip", target: nil, action: nil)
    private let doneButton = NSButton(title: "Done", target: nil, action: nil)
    private let skippedButton = NSButton(title: "Skipped", target: nil, action: nil)
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
        imageView.isHidden = true
        visualView.configure(kind: .none)

        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        progressLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        progressLabel.textColor = .lightGray
        progressLabel.alignment = .center

        startNowButton.bezelStyle = .rounded
        startNowButton.action = #selector(startNowClicked)
        skipButton.bezelStyle = .rounded
        skipButton.action = #selector(skipClicked)
        doneButton.bezelStyle = .rounded
        doneButton.action = #selector(doneClicked)
        skippedButton.bezelStyle = .rounded
        skippedButton.action = #selector(skipClicked)
        doneButton.isHidden = true
        skippedButton.isHidden = true

        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12

        descriptionLabel.font = NSFont.systemFont(ofSize: 11)
        descriptionLabel.textColor = .lightGray
        descriptionLabel.alignment = .center
        descriptionLabel.preferredMaxLayoutWidth = 260

        let stack = NSStackView(views: [visualView, titleLabel, descriptionLabel, progressLabel, buttonStack])
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
        doneButton.isHidden = true
        skippedButton.isHidden = true

        buttonStack.views.forEach { buttonStack.removeView($0) }
        buttonStack.addView(startNowButton, in: .leading)
        buttonStack.addView(skipButton, in: .trailing)

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

    @objc private func startNowClicked() {
        countdownTimer?.invalidate()
        beginSequence()
    }

    @objc private func skipClicked() {
        stop()
        onCompletion?(false)
    }

    @objc private func doneClicked() {
        stop()
        onCompletion?(true)
    }

    private func beginSequence() {
        buttonStack.views.forEach { buttonStack.removeView($0) }
        buttonStack.addView(skipButton, in: .trailing)
        skipButton.title = "Skip"
        playNext()
    }

    private func playNext() {
        guard !remainingItems.isEmpty else {
            showAllDone()
            return
        }
        let item = remainingItems.removeFirst()
        titleLabel.stringValue = item.title
        descriptionLabel.stringValue = item.description
        if let imageURL = DataStore.shared.imageURL(for: item.image),
           let image = NSImage(contentsOf: imageURL) {
            visualView.configure(kind: .none)
            visualView.isHidden = true
            imageView.isHidden = false
            imageView.image = image
        } else {
            visualView.isHidden = false
            imageView.isHidden = true
            visualView.configure(kind: ExerciseVisualView.Kind(rawValue: item.visual ?? "none") ?? .none)
            visualView.startAnimating()
        }
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
        visualView.stopAnimating()
        visualView.configure(kind: .none)
        imageView.image = nil
        titleLabel.stringValue = headerText
        progressLabel.stringValue = "All exercises finished."
        buttonStack.views.forEach { buttonStack.removeView($0) }
        doneButton.isHidden = false
        skippedButton.isHidden = false
        buttonStack.addView(doneButton, in: .leading)
        buttonStack.addView(skippedButton, in: .trailing)
    }

    func stop() {
        visualView.stopAnimating()
        countdownTimer?.invalidate()
        countdownTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}
