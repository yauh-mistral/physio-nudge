import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var overlayPanel: OverlayPanel?
    private var overlayController: OverlayViewController?
    private var breakTimer: Timer?

    private let catalog = ExerciseCatalog()
    private var isPaused = false
    private var intervalMinutes = 60
    private var corner = OverlayCorner.bottomRight

    private var pauseMenuItem: NSMenuItem?
    private let overlaySize = NSSize(width: 300, height: 300)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        scheduleNextBreak()

        // NFR-10: recalibrate the timer after waking from sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    // MARK: - Menu bar icon & menu

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "figure.flexibility",
                                     accessibilityDescription: "Physio Nudge")
        if item.button?.image == nil {
            item.button?.title = "\u{1F9D8}"
        }

        let menu = NSMenu()
        // Never let AppKit auto-disable our items: every action has an
        // explicit target, and auto-validation could grey them out.
        menu.autoenablesItems = false

        let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePaused), keyEquivalent: "p")
        pauseItem.target = self
        pauseItem.isEnabled = true
        menu.addItem(pauseItem)
        pauseMenuItem = pauseItem

        let nowItem = NSMenuItem(title: "Exercise now", action: #selector(showOverlayNow), keyEquivalent: "n")
        nowItem.target = self
        nowItem.isEnabled = true
        menu.addItem(nowItem)

        menu.addItem(.separator())

        // FR-07: interval submenu
        let intervalMenu = NSMenu()
        intervalMenu.autoenablesItems = false
        for minutes in [15, 30, 45, 60, 90] {
            let entry = NSMenuItem(title: "Every \(minutes) minutes",
                                   action: #selector(setInterval(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = minutes
            entry.isEnabled = true
            entry.state = minutes == intervalMinutes ? .on : .off
            intervalMenu.addItem(entry)
        }
        let intervalMenuItem = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        intervalMenuItem.isEnabled = true
        intervalMenuItem.submenu = intervalMenu
        menu.addItem(intervalMenuItem)

        // FR-08: corner submenu
        let cornerMenu = NSMenu()
        cornerMenu.autoenablesItems = false
        for (index, candidate) in OverlayCorner.allCases.enumerated() {
            let entry = NSMenuItem(title: candidate.rawValue,
                                   action: #selector(setCorner(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = index
            entry.isEnabled = true
            entry.state = candidate == corner ? .on : .off
            cornerMenu.addItem(entry)
        }
        let cornerMenuItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        cornerMenuItem.isEnabled = true
        cornerMenuItem.submenu = cornerMenu
        menu.addItem(cornerMenuItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit PhysioNudge",
                                  action: #selector(NSApplication.terminate(_:)),
                                  keyEquivalent: "q")
        quitItem.target = NSApp
        quitItem.isEnabled = true
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    // MARK: - Timer

    private func scheduleNextBreak() {
        breakTimer?.invalidate()
        guard !isPaused else { return }
        // .common mode: the timer must also fire while a menu is open
        // or during window resizing drags.
        breakTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(intervalMinutes * 60),
            repeats: false
        ) { [weak self] _ in
            self?.showOverlay()
        }
        if let timer = breakTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    @objc private func sessionDidWake() {
        scheduleNextBreak()
    }

    // MARK: - Menu actions

    @objc private func togglePaused() {
        isPaused.toggle()
        pauseMenuItem?.title = isPaused ? "Resume" : "Pause"
        scheduleNextBreak()
    }

    @objc private func showOverlayNow() {
        showOverlay()
    }

    @objc private func setInterval(_ sender: NSMenuItem) {
        intervalMinutes = sender.tag
        sender.menu?.items.forEach { $0.state = $0.tag == sender.tag ? .on : .off }
        scheduleNextBreak()
    }

    @objc private func setCorner(_ sender: NSMenuItem) {
        let all = OverlayCorner.allCases
        guard all.indices.contains(sender.tag) else { return }
        corner = all[sender.tag]
        sender.menu?.items.forEach { $0.state = $0.tag == sender.tag ? .on : .off }
    }

    // MARK: - Overlay (FR-02 to FR-04, NFR-11)

    private func showOverlay() {
        scheduleNextBreak()
        guard overlayPanel == nil else { return }

        let panel = OverlayPanel(size: overlaySize, corner: corner)
        let controller = OverlayViewController()
        panel.contentViewController = controller

        overlayPanel = panel
        overlayController = controller

        let finish = { [weak self, weak panel, weak controller] in
            controller?.stop()
            panel?.dismiss {
                self?.overlayPanel = nil
                self?.overlayController = nil
            }
        }

        if let exercise = catalog.randomExercise() {
            controller.play(exercise: exercise,
                            directory: catalog.exerciseDirectory,
                            perGifSeconds: catalog.catalog.perGifSeconds ?? 6,
                            onFinish: finish)
        } else {
            // FR-11: fallback if no usable visuals exist.
            controller.play(exercise: Exercise(
                                title: "Time for a break!",
                                caption: "No exercise visuals found. Place GIF files and exercises.json in the Exercises folder — see requirements/05-exercise-content-and-visuals.md.",
                                gifs: []),
                            directory: catalog.exerciseDirectory,
                            perGifSeconds: 8,
                            onFinish: finish)
        }

        panel.present()
    }
}
