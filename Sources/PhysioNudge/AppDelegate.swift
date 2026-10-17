import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var overlayPanel: OverlayPanel?
    private var overlayController: OverlayViewController?

    private let schedulerService = SchedulerService()
    private var libraryWindow: LibraryWindowController?
    private var nudgeWindow: NudgeWindowController?
    private var settingsWindow: SettingsWindowController?

    private let overlaySize = NSSize(width: 300, height: 300)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        schedulerService.onPresent = { [weak self] profile, exercises in
            self?.present(profileName: profile.name, exercises: exercises)
        }
        schedulerService.start()
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
        menu.autoenablesItems = false

        let libraryItem = NSMenuItem(title: "Open Library",
                                     action: #selector(openLibrary), keyEquivalent: "l")
        libraryItem.target = self
        libraryItem.isEnabled = true
        menu.addItem(libraryItem)

        let nudgesItem = NSMenuItem(title: "Configure Nudges",
                                    action: #selector(openNudges), keyEquivalent: "n")
        nudgesItem.target = self
        nudgesItem.isEnabled = true
        menu.addItem(nudgesItem)

        let settingsItem = NSMenuItem(title: "Settings",
                                      action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.isEnabled = true
        menu.addItem(settingsItem)

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

    // MARK: - Windows

    @objc private func openLibrary() {
        if libraryWindow == nil {
            let controller = LibraryWindowController()
            controller.onDoNow = { [weak self] exercise in
                self?.present(exercise: exercise)
            }
            libraryWindow = controller
        }
        libraryWindow?.reload()
        libraryWindow?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openNudges() {
        if nudgeWindow == nil {
            nudgeWindow = NudgeWindowController()
        }
        nudgeWindow?.reload()
        nudgeWindow?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Callbacks from windows

    func schedulerDidReschedule() {
        schedulerService.reschedule()
    }

    // MARK: - Overlay presentation

    private func present(profileName: String, exercises: [LibraryExercise]) {
        guard overlayPanel == nil else {
            // Another presentation is active; the queue drains on finish.
            return
        }
        let corner = DataStore.shared.currentCorner
        let panel = OverlayPanel(size: overlaySize, corner: corner)
        let controller = OverlayViewController()
        panel.contentViewController = controller
        panel.present(at: corner)

        overlayPanel = panel
        overlayController = controller

        controller.present(profileName: profileName,
                           exercises: exercises,
                           directory: DataStore.shared.directory,
                           startMode: .auto,
                           autoDelaySeconds: 10) { [weak self] _ in
            self?.dismissOverlay()
            self?.schedulerService.overlayDidFinish()
        }
    }

    private func present(exercise: LibraryExercise) {
        guard overlayPanel == nil else { return }
        let corner = DataStore.shared.currentCorner
        let panel = OverlayPanel(size: overlaySize, corner: corner)
        let controller = OverlayViewController()
        panel.contentViewController = controller
        panel.present(at: corner)

        overlayPanel = panel
        overlayController = controller

        controller.present(profileName: exercise.title,
                           exercises: [exercise],
                           directory: DataStore.shared.directory,
                           startMode: .auto,
                           autoDelaySeconds: 5) { [weak self] _ in
            self?.dismissOverlay()
        }
    }

    private func dismissOverlay() {
        overlayController?.stop()
        let panel = overlayPanel
        overlayController = nil
        overlayPanel = nil
        panel?.dismiss()
    }
}
