import AppKit

/// Presents one profile: title, caption, visual per exercise, sequential
/// playback with reps/duration, then the "All done?" confirmation.
/// Start modes: auto (countdown delay) or click (Start button).
final class OverlayViewController: NSViewController {
    private let effectView = NSVisualEffectView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let captionLabel = NSTextField(wrappingLabelWithString: "")
    private let progressLabel = NSTextField(labelWithString: "")
    private let imageView = NSImageView()
    private let startButton = NSButton(title: "Start", target: nil, action: nil)
    private let noButton = NSButton(title: "No", target: nil, action: nil)
    private let yesButton = NSButton(title: "Yes", target: nil, action: nil)
    private let buttonStack = NSStackView()

    private var animator: GifAnimator?
    private var playbackTimer: Timer?
    private var gifQueue: [URL] = []
    private var gifDirectory: URL = URL(fileURLWithPath: "/")
    private var onCompletion: ((Bool) -> Void)?

    private var profileName = ""
    private var remainingExercises: [LibraryExercise] = []
    private var startMode: StartMode = .auto
    private var countdownSeconds = 10
    private var countdownTimer: Timer?

    enum StartMode {
        case auto
        case click
    }

    override func loadView() {
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
        progressLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        progressLabel.textColor = .white
        progressLabel.alignment = .center

        startButton.bezelStyle = .rounded
        startButton.action = #selector(startClicked)
        noButton.bezelStyle = .rounded
        noButton.action = #selector(noClicked)
        yesButton.bezelStyle = .rounded
        yesButton.action = #selector(yesClicked)

        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12

        let stack = NSStackView(views: [imageView, titleLabel, captionLabel, progressLabel, buttonStack])
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

    /// Present a whole profile. `completion(true)` = user confirmed done,
    /// `completion(false)` = dismissed without confirmation.
    func present(profileName: String,
                 exercises: [LibraryExercise],
                 directory: URL,
                 startMode: StartMode,
                 autoDelaySeconds: Int,
                 completion: @escaping (Bool) -> Void) {
        self.profileName = profileName
        self.remainingExercises = exercises
        self.startMode = startMode
        self.countdownSeconds = max(0, min(60, autoDelaySeconds))
        self.onCompletion = completion
        gifDirectory = directory

        titleLabel.stringValue = profileName
        captionLabel.stringValue = ""
        progressLabel.stringValue = ""
        buttonStack.views.forEach { buttonStack.removeView($0) }
        yesButton.isHidden = true
        startButton.isHidden = true

        noButton.isHidden = false
        buttonStack.addView(noButton, in: .trailing)
        switch startMode {
        case .auto:
            startCountdown()
        case .click:
            startButton.isHidden = false
            buttonStack.addView(startButton, in: .leading)
        }
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

    @objc private func startClicked() {
        countdownTimer?.invalidate()
        beginSequence()
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
        buttonStack.views.forEach { buttonStack.removeView($0) }
        noButton.isHidden = false
        buttonStack.addView(noButton, in: .trailing)
        playNextExercise()
    }

    private func playNextExercise() {
        guard !remainingExercises.isEmpty else {
            showAllDone()
            return
        }
        let exercise = remainingExercises.removeFirst()
        titleLabel.stringValue = exercise.title
        captionLabel.stringValue = exercise.caption

        let volume = exercise.reps != nil ? "\(exercise.reps!)x" : "\(exercise.durationSeconds ?? 0) s"
        progressLabel.stringValue = volume

        gifQueue = exercise.gifs.map { gifDirectory.appendingPathComponent($0) }
        if gifQueue.isEmpty {
            imageView.image = NSImage(systemSymbolName: "figure.flexibility",
                                      accessibilityDescription: nil)
        } else {
            playNextGif()
        }

        let seconds = TimeInterval(exercise.durationSeconds ?? 0)
        if exercise.reps == nil && seconds > 0 {
            playbackTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                self?.playNextExercise()
            }
        } else {
            let fallbackSeconds = 10.0
            playbackTimer = Timer.scheduledTimer(withTimeInterval: fallbackSeconds, repeats: false) { [weak self] _ in
                self?.playNextExercise()
            }
        }
    }

    private func playNextGif() {
        playbackTimer?.invalidate()
        animator?.stop()
        animator = nil
        guard !gifQueue.isEmpty else { return }
        let url = gifQueue.removeFirst()
        if let nextAnimator = GifAnimator(url: url) {
            animator = nextAnimator
            nextAnimator.start(in: imageView)
        } else {
            imageView.image = NSImage(systemSymbolName: "figure.flexibility",
                                      accessibilityDescription: nil)
        }
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
            self?.playNextGif()
        }
    }

    private func showAllDone() {
        animator?.stop()
        imageView.image = NSImage(systemSymbolName: "checkmark.circle",
                                   accessibilityDescription: nil)
        titleLabel.stringValue = profileName
        captionLabel.stringValue = "All done?"
        progressLabel.stringValue = ""
        buttonStack.views.forEach { buttonStack.removeView($0) }
        yesButton.isHidden = false
        noButton.isHidden = false
        buttonStack.addView(yesButton, in: .leading)
        buttonStack.addView(noButton, in: .trailing)
    }

    func stop() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        animator?.stop()
        animator = nil
    }
}
