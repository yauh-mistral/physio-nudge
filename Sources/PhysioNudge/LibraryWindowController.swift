import AppKit

/// Library window with two tabs: Exercises and Profiles.
/// Exercises: simple list + add via text field (Enter or button).
/// Profiles: list + editor (name, entries with per-entry amount);
/// add existing or new exercises, edit amounts, remove entries, save.
final class LibraryWindowController: NSWindowController, NSWindowDelegate {
    private let tabView: NSTabView = {
        let view = NSTabView()
        view.tabViewType = .topTabsBezelBorder
        return view
    }()

    // Exercises tab
    private let exerciseTable = NSTableView()
    private let exerciseField = NSTextField()
    private let addExerciseButton = NSButton(title: "Add", target: nil, action: nil)
    private let deleteExerciseButton = NSButton(title: "Delete Selected", target: nil, action: nil)

    // Profiles tab
    private let profileTable = NSTableView()
    private let profileNameField = NSTextField()
    private let entriesTable = NSTableView()
    private let newProfileButton = NSButton(title: "New Profile", target: nil, action: nil)
    private let addEntryButton = NSButton(title: "Add Exercise…", target: nil, action: nil)
    private let editAmountButton = NSButton(title: "Edit Amount…", target: nil, action: nil)
    private let removeEntryButton = NSButton(title: "Remove Entry", target: nil, action: nil)
    private let saveProfileButton = NSButton(title: "Save Profile", target: nil, action: nil)

    private var selectedProfile: Profile?
    private var isSelectingProgrammatically = false

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        panel.title = "Library"
        super.init(window: panel)
        panel.delegate = self
        setupContent()
        reload()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Layout

    private func setupContent() {
        guard let contentView = window?.contentView else { return }
        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        setupExercisesTab()
        setupProfilesTab()
    }

    private func setupExercisesTab() {
        let tabItem = NSTabViewItem(identifier: NSUserInterfaceItemIdentifier("exercises"))
        tabItem.label = "Exercises"
        tabItem.view = NSView()
        tabView.addTabViewItem(tabItem)
        guard let pane = tabItem.view else { return }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("exercise"))
        exerciseTable.addTableColumn(column)
        exerciseTable.style = .inset
        exerciseTable.delegate = self
        exerciseTable.dataSource = self
        exerciseTable.rowHeight = 26

        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = exerciseTable
        scroll.hasVerticalScroller = true

        exerciseField.placeholderString = "New exercise title…"
        exerciseField.target = self
        exerciseField.action = #selector(addExerciseClicked)

        addExerciseButton.bezelStyle = .rounded
        addExerciseButton.target = self
        addExerciseButton.action = #selector(addExerciseClicked)

        deleteExerciseButton.bezelStyle = .rounded
        deleteExerciseButton.target = self
        deleteExerciseButton.action = #selector(deleteExerciseClicked)

        let inputRow = NSStackView(views: [exerciseField, addExerciseButton, deleteExerciseButton])
        inputRow.orientation = .horizontal
        inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false
        exerciseField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        pane.addSubview(scroll)
        pane.addSubview(inputRow)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: pane.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: inputRow.topAnchor, constant: -8),
            inputRow.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            inputRow.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
        ])
    }

    private func setupProfilesTab() {
        let tabItem = NSTabViewItem(identifier: NSUserInterfaceItemIdentifier("profiles"))
        tabItem.label = "Profiles"
        tabItem.view = NSView()
        tabView.addTabViewItem(tabItem)
        guard let pane = tabItem.view else { return }

        let profileColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("profile"))
        profileTable.addTableColumn(profileColumn)
        profileTable.style = .inset
        profileTable.delegate = self
        profileTable.dataSource = self
        profileTable.rowHeight = 26

        let profileScroll = NSScrollView()
        profileScroll.translatesAutoresizingMaskIntoConstraints = false
        profileScroll.documentView = profileTable
        profileScroll.hasVerticalScroller = true

        newProfileButton.bezelStyle = .rounded
        newProfileButton.target = self
        newProfileButton.action = #selector(newProfileClicked)

        let profileBox = NSBox()
        profileBox.title = "Profiles"
        profileBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        profileBox.translatesAutoresizingMaskIntoConstraints = false
        profileBox.addSubview(profileScroll)
        profileBox.addSubview(newProfileButton)
        NSLayoutConstraint.activate([
            profileScroll.leadingAnchor.constraint(equalTo: profileBox.leadingAnchor, constant: 8),
            profileScroll.trailingAnchor.constraint(equalTo: profileBox.trailingAnchor, constant: -8),
            profileScroll.topAnchor.constraint(equalTo: profileBox.topAnchor, constant: 8),
            profileScroll.bottomAnchor.constraint(equalTo: newProfileButton.topAnchor, constant: -8),
            newProfileButton.leadingAnchor.constraint(equalTo: profileBox.leadingAnchor, constant: 8),
            newProfileButton.bottomAnchor.constraint(equalTo: profileBox.bottomAnchor, constant: -8),
        ])

        profileNameField.placeholderString = "Profile name"
        profileNameField.translatesAutoresizingMaskIntoConstraints = false

        let entryColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("entry"))
        entriesTable.addTableColumn(entryColumn)
        entriesTable.style = .inset
        entriesTable.delegate = self
        entriesTable.dataSource = self
        entriesTable.rowHeight = 26

        let entriesScroll = NSScrollView()
        entriesScroll.translatesAutoresizingMaskIntoConstraints = false
        entriesScroll.documentView = entriesTable
        entriesScroll.hasVerticalScroller = true

        addEntryButton.bezelStyle = .rounded
        addEntryButton.target = self
        addEntryButton.action = #selector(addEntryClicked)
        editAmountButton.bezelStyle = .rounded
        editAmountButton.target = self
        editAmountButton.action = #selector(editAmountClicked)
        removeEntryButton.bezelStyle = .rounded
        removeEntryButton.target = self
        removeEntryButton.action = #selector(removeEntryClicked)
        saveProfileButton.bezelStyle = .rounded
        saveProfileButton.target = self
        saveProfileButton.action = #selector(saveProfileClicked)

        let editorButtons = NSStackView(views: [addEntryButton, editAmountButton, removeEntryButton, saveProfileButton])
        editorButtons.orientation = .horizontal
        editorButtons.spacing = 8
        editorButtons.translatesAutoresizingMaskIntoConstraints = false

        let editorBox = NSBox()
        editorBox.title = "Profile Editor"
        editorBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        editorBox.translatesAutoresizingMaskIntoConstraints = false
        editorBox.addSubview(profileNameField)
        editorBox.addSubview(entriesScroll)
        editorBox.addSubview(editorButtons)
        NSLayoutConstraint.activate([
            profileNameField.leadingAnchor.constraint(equalTo: editorBox.leadingAnchor, constant: 8),
            profileNameField.trailingAnchor.constraint(equalTo: editorBox.trailingAnchor, constant: -8),
            profileNameField.topAnchor.constraint(equalTo: editorBox.topAnchor, constant: 8),
            entriesScroll.leadingAnchor.constraint(equalTo: editorBox.leadingAnchor, constant: 8),
            entriesScroll.trailingAnchor.constraint(equalTo: editorBox.trailingAnchor, constant: -8),
            entriesScroll.topAnchor.constraint(equalTo: profileNameField.bottomAnchor, constant: 8),
            entriesScroll.bottomAnchor.constraint(equalTo: editorButtons.topAnchor, constant: -8),
            editorButtons.leadingAnchor.constraint(equalTo: editorBox.leadingAnchor, constant: 8),
            editorButtons.bottomAnchor.constraint(equalTo: editorBox.bottomAnchor, constant: -8),
        ])

        pane.addSubview(profileBox)
        pane.addSubview(editorBox)
        NSLayoutConstraint.activate([
            profileBox.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            profileBox.widthAnchor.constraint(equalTo: pane.widthAnchor, multiplier: 0.38),
            profileBox.topAnchor.constraint(equalTo: pane.topAnchor),
            profileBox.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
            editorBox.leadingAnchor.constraint(equalTo: profileBox.trailingAnchor, constant: 12),
            editorBox.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            editorBox.topAnchor.constraint(equalTo: pane.topAnchor),
            editorBox.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
        ])
    }

    // MARK: - Exercises actions

    @objc private func addExerciseClicked() {
        let title = exerciseField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        DataStore.shared.add(exercise: Exercise(id: UUID().uuidString, title: title, visual: nil))
        exerciseField.stringValue = ""
        reload()
    }

    @objc private func deleteExerciseClicked() {
        let row = exerciseTable.selectedRow
        guard row >= 0, row < DataStore.shared.library.exercises.count else { return }
        let exercise = DataStore.shared.library.exercises[row]
        DataStore.shared.remove(exercise: exercise)
        reload()
    }

    // MARK: - Profiles actions

    @objc private func newProfileClicked() {
        beginNewProfile()
    }

    @objc private func addEntryClicked() {
        guard selectedProfile != nil else { return }
        let menu = NSMenu()
        for exercise in DataStore.shared.library.exercises {
            let item = NSMenuItem(title: exercise.title,
                                  action: #selector(entryExercisePicked(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = exercise.id
            menu.addItem(item)
        }
        let addNew = NSMenuItem(title: "New Exercise…",
                                action: #selector(entryNewExercisePicked),
                                keyEquivalent: "")
        addNew.target = self
        menu.addItem(addNew)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: addEntryButton)
    }

    @objc private func entryExercisePicked(_ sender: NSMenuItem) {
        guard let profile = selectedProfile,
              let exerciseId = sender.representedObject as? String else { return }
        var updated = profile
        updated.entries.append(ProfileEntry(exerciseId: exerciseId, reps: nil, seconds: nil))
        selectedProfile = updated
        reload()
    }

    @objc private func entryNewExercisePicked() {
        guard let title = Self.promptText(title: "New Exercise",
                                          message: "Title of the new exercise:"),
              !title.isEmpty else { return }
        let exercise = Exercise(id: UUID().uuidString, title: title, visual: nil)
        DataStore.shared.add(exercise: exercise)
        guard var profile = selectedProfile else { return }
        profile.entries.append(ProfileEntry(exerciseId: exercise.id, reps: nil, seconds: nil))
        selectedProfile = profile
        reload()
    }

    @objc private func editAmountClicked() {
        guard var profile = selectedProfile else { return }
        let row = entriesTable.selectedRow
        guard row >= 0, row < profile.entries.count else {
            Self.showInfo(title: "Edit Amount",
                          message: "Select an entry in the list first.")
            return
        }
        let entry = profile.entries[row]
        let exerciseTitle = DataStore.shared.library.exercise(id: entry.exerciseId)?.title ?? "Exercise"
        let current = entry.reps != nil ? "\(entry.reps!)" : "\(entry.seconds ?? 0)s"
        guard let text = Self.promptText(title: "Edit \(exerciseTitle)",
                                         message: "Amount: plain number = reps (e.g. '10'). Or seconds with 's' (e.g. '30s').",
                                         defaultValue: current) else { return }
        let normalized = text.trimmingCharacters(in: .whitespaces).lowercased()
        if normalized.hasSuffix("s"), let seconds = Int(normalized.dropLast()) {
            profile.entries[row] = ProfileEntry(exerciseId: entry.exerciseId, reps: nil, seconds: seconds)
        } else if let reps = Int(normalized) {
            profile.entries[row] = ProfileEntry(exerciseId: entry.exerciseId, reps: reps, seconds: nil)
        } else {
            return
        }
        selectedProfile = profile
        reload()
    }

    @objc private func removeEntryClicked() {
        guard var profile = selectedProfile else { return }
        let row = entriesTable.selectedRow
        guard row >= 0, row < profile.entries.count else { return }
        profile.entries.remove(at: row)
        selectedProfile = profile
        reload()
    }

    @objc private func saveProfileClicked() {
        guard var profile = selectedProfile else { return }
        profile.name = profileNameField.stringValue.isEmpty ? "Profile" : profileNameField.stringValue
        DataStore.shared.update(profile: profile)
        selectedProfile = profile
        reload()
    }

    // MARK: - Helpers

    private static func promptText(title: String,
                                   message: String,
                                   defaultValue: String = "") -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = defaultValue
        alert.accessoryView = input
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return input.stringValue
    }

    private static func showInfo(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Data

    private var exercises: [Exercise] { DataStore.shared.library.exercises }
    private var profiles: [Profile] { DataStore.shared.library.profiles }

    func reload() {
        exerciseTable.reloadData()
        profileTable.reloadData()
        entriesTable.reloadData()
        let hasProfile = selectedProfile != nil
        addEntryButton.isEnabled = hasProfile
        editAmountButton.isEnabled = hasProfile
        removeEntryButton.isEnabled = hasProfile
        saveProfileButton.isEnabled = hasProfile
    }

    func select(profile: Profile) {
        isSelectingProgrammatically = true
        selectedProfile = profile
        profileNameField.stringValue = profile.name
        reload()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profileTable.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        isSelectingProgrammatically = false
    }

    func beginNewProfile() {
        selectedProfile = Profile(id: UUID().uuidString, name: "New Profile", entries: [])
        profileNameField.stringValue = "New Profile"
        reload()
        tabView.selectTabViewItem(at: 1)
    }
}

extension LibraryWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == exerciseTable {
            return exercises.count
        }
        if tableView == profileTable {
            return profiles.count
        }
        return selectedProfile?.entries.count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"),
                                       owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        if tableView == exerciseTable {
            cell.stringValue = exercises[row].title
        } else if tableView == profileTable {
            cell.stringValue = profiles[row].name
        } else if let profile = selectedProfile, row < profile.entries.count {
            let entry = profile.entries[row]
            let title = DataStore.shared.library.exercise(id: entry.exerciseId)?.title ?? "?"
            if let reps = entry.reps {
                cell.stringValue = "\(reps)x \(title)"
            } else if let seconds = entry.seconds {
                cell.stringValue = "\(seconds) s \(title)"
            } else {
                cell.stringValue = "\(title) — no amount yet"
            }
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else { return }
        if table == profileTable {
            // Guard against re-entrant selection events caused by our own
            // programmatic selectRowIndexes during reloadData (crash fix).
            if isSelectingProgrammatically { return }
            let row = profileTable.selectedRow
            guard row >= 0, row < profiles.count else { return }
            select(profile: profiles[row])
        }
    }
}
