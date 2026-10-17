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

        schedulerService.onPresent = { [weak self] profile in
            self?.present(profileName: profile.name, items: Self.overlayItems(for: profile))
        }
        schedulerService.start()
    }

    static func overlayItems(for profile: Profile) -> [OverlayItem] {
        profile.entries.compactMap { entry in
            guard let exercise = DataStore.shared.library.exercise(id: entry.exerciseId) else {
                return nil
            }
            return OverlayItem(title: exercise.title, reps: entry.reps, seconds: entry.seconds)
        }
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
            libraryWindow = LibraryWindowController()
        }
        libraryWindow?.reload()
        libraryWindow?.showWindow(self)
        libraryWindow?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openNudges() {
        if nudgeWindow == nil {
            let controller = NudgeWindowController()
            controller.onNewProfile = { [weak self] in
                self?.openLibraryCreatingProfile()
            }
            nudgeWindow = controller
        }
        nudgeWindow?.reload()
        nudgeWindow?.showWindow(self)
        nudgeWindow?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.showWindow(self)
        settingsWindow?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Opens the Library and starts a fresh profile editor (jump target
    /// for "New Profile…" in the nudge configuration).
    private func openLibraryCreatingProfile() {
        openLibrary()
        libraryWindow?.beginNewProfile()
    }

    // MARK: - Callbacks from windows

    func schedulerDidReschedule() {
        schedulerService.reschedule()
    }

    // MARK: - Overlay presentation

    private func present(profileName: String, items: [OverlayItem]) {
        guard overlayPanel == nil else { return }
        showOverlay(profileName: profileName, items: items) { [weak self] _ in
            self?.schedulerService.overlayDidFinish()
        }
    }

    private func showOverlay(profileName: String,
                             items: [OverlayItem],
                             completion: @escaping (Bool) -> Void) {
        guard !items.isEmpty else { return }
        let corner = DataStore.shared.currentCorner
        let panel = OverlayPanel(size: overlaySize, corner: corner)
        let controller = OverlayViewController()
        panel.contentViewController = controller
        panel.present(at: corner)

        overlayPanel = panel
        overlayController = controller

        controller.present(header: profileName,
                       items: items,
                       autoDelaySeconds: 10) { [weak self] _ in
            self?.dismissOverlay()
            completion(false)
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
