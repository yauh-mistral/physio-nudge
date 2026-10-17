import AppKit

/// Library window: exercises and profiles.
/// Exercises are simple text lines; a profile combines 1...x exercises,
/// each with its own amount (reps) or time (seconds).
/// From a profile you can select existing exercises or add a new one.
final class LibraryWindowController: NSWindowController, NSWindowDelegate {
    private let exerciseTable = NSTableView()
    private let profileTable = NSTableView()
    private let entriesTable = NSTableView()
    private let exerciseField = NSTextField()
    private let addExerciseButton = NSButton(title: "Add Exercise", target: nil, action: nil)
    private let profileNameField = NSTextField()
    private let addProfileButton = NSButton(title: "New Profile", target: nil, action: nil)
    private let saveProfileButton = NSButton(title: "Save Profile", target: nil, action: nil)
    private let addEntryButton = NSButton(title: "Add Exercise to Profile", target: nil, action: nil)
    private let removeEntryButton = NSButton(title: "Remove Selected", target: nil, action: nil)

    private var selectedProfile: Profile?

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 760, height: 480),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        panel.title = "Library"
        super.init(window: panel)
        panel.delegate = self
        setupContent()
        reload()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        // Exercises pane
        let exerciseColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("exercise"))
        exerciseTable.addTableColumn(exerciseColumn)
        exerciseTable.style = .inset
        exerciseTable.delegate = self
        exerciseTable.dataSource = self
        exerciseTable.rowHeight = 24

        let exerciseScroll = NSScrollView()
        exerciseScroll.documentView = exerciseTable
        exerciseScroll.hasVerticalScroller = true

        addExerciseButton.bezelStyle = .rounded
        addExerciseButton.target = self
        addExerciseButton.action = #selector(addExerciseClicked)

        let exercisePane = NSStackView()
        exercisePane.orientation = .vertical
        exercisePane.spacing = 8
        exercisePane.addArrangedSubview(exerciseScroll)
        exercisePane.addArrangedSubview(exerciseField)
        exercisePane.addArrangedSubview(addExerciseButton)

        let exerciseBox = NSBox()
        exerciseBox.title = "Exercises"
        exerciseBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        exerciseBox.contentView = exercisePane

        // Profiles pane
        let profileColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("profile"))
        profileTable.addTableColumn(profileColumn)
        profileTable.style = .inset
        profileTable.delegate = self
        profileTable.dataSource = self
        profileTable.rowHeight = 24

        let profileScroll = NSScrollView()
        profileScroll.documentView = profileTable
        profileScroll.hasVerticalScroller = true

        addProfileButton.bezelStyle = .rounded
        addProfileButton.target = self
        addProfileButton.action = #selector(addProfileClicked)

        let profilePane = NSStackView()
        profilePane.orientation = .vertical
        profilePane.spacing = 8
        profilePane.addArrangedSubview(profileScroll)
        profilePane.addArrangedSubview(addProfileButton)

        let profileBox = NSBox()
        profileBox.title = "Profiles"
        profileBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        profileBox.contentView = profilePane

        // Profile editor pane
        let entryColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("entry"))
        entriesTable.addTableColumn(entryColumn)
        entriesTable.style = .inset
        entriesTable.delegate = self
        entriesTable.dataSource = self
        entriesTable.rowHeight = 24

        let entriesScroll = NSScrollView()
        entriesScroll.documentView = entriesTable
        entriesScroll.hasVerticalScroller = true

        saveProfileButton.bezelStyle = .rounded
        saveProfileButton.target = self
        saveProfileButton.action = #selector(saveProfileClicked)
        saveProfileButton.isEnabled = false

        addEntryButton.bezelStyle = .rounded
        addEntryButton.target = self
        addEntryButton.action = #selector(addEntryClicked)
        addEntryButton.isEnabled = false

        removeEntryButton.bezelStyle = .rounded
        removeEntryButton.target = self
        removeEntryButton.action = #selector(removeEntryClicked)
        removeEntryButton.isEnabled = false

        let editorPane = NSStackView()
        editorPane.orientation = .vertical
        editorPane.spacing = 8
        editorPane.addArrangedSubview(profileNameField)
        editorPane.addArrangedSubview(entriesScroll)
        let editorButtons = NSStackView(views: [addEntryButton, removeEntryButton, saveProfileButton])
        editorButtons.orientation = .horizontal
        editorButtons.spacing = 8
        editorPane.addArrangedSubview(editorButtons)

        let editorBox = NSBox()
        editorBox.title = "Profile Editor"
        editorBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        editorBox.contentView = editorPane

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(exerciseBox)
        split.addArrangedSubview(profileBox)
        split.addArrangedSubview(editorBox)
        split.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(split)
        NSLayoutConstraint.activate([
            split.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            split.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            split.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            split.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Actions

    @objc private func addExerciseClicked() {
        let title = exerciseField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        DataStore.shared.add(exercise: Exercise(id: UUID().uuidString, title: title))
        exerciseField.stringValue = ""
        reload()
    }

    @objc private func addProfileClicked() {
        selectedProfile = Profile(id: UUID().uuidString,
                                  name: "New Profile",
                                  entries: [])
        profileNameField.stringValue = selectedProfile!.name
        reload()
    }

    @objc private func addEntryClicked() {
        guard selectedProfile != nil else { return }
        let menu = NSMenu()
        for exercise in DataStore.shared.library.exercises {
            let item = NSMenuItem(title: exercise.title, action: #selector(entryExercisePicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = exercise.id
            menu.addItem(item)
        }
        let addNew = NSMenuItem(title: "New Exercise…", action: #selector(entryNewExercisePicked), keyEquivalent: "")
        addNew.target = self
        menu.addItem(addNew)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: addEntryButton)
    }

    @objc private func entryExercisePicked(_ sender: NSMenuItem) {
        guard let profile = selectedProfile,
              let exerciseId = sender.representedObject as? String else { return }
        var updated = profile
        updated.entries.append(ProfileEntry(exerciseId: exerciseId, reps: 10, seconds: nil))
        selectedProfile = updated
        reload()
    }

    @objc private func entryNewExercisePicked() {
        let alert = NSAlert()
        alert.messageText = "New Exercise"
        alert.informativeText = "Title of the new exercise:"
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        alert.accessoryView = input
        guard alert.runModal() == .alertFirstButtonReturn,
              !input.stringValue.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let exercise = Exercise(id: UUID().uuidString,
                                title: input.stringValue.trimmingCharacters(in: .whitespaces))
        DataStore.shared.add(exercise: exercise)
        guard var profile = selectedProfile else { return }
        profile.entries.append(ProfileEntry(exerciseId: exercise.id, reps: 10, seconds: nil))
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

    // MARK: - Table data

    private var exercises: [Exercise] { DataStore.shared.library.exercises }
    private var profiles: [Profile] { DataStore.shared.library.profiles }

    func reload() {
        exerciseTable.reloadData()
        profileTable.reloadData()
        entriesTable.reloadData()
        saveProfileButton.isEnabled = selectedProfile != nil
        addEntryButton.isEnabled = selectedProfile != nil
        removeEntryButton.isEnabled = selectedProfile != nil && !selectedProfile!.entries.isEmpty
    }

    func select(profile: Profile) {
        selectedProfile = profile
        profileNameField.stringValue = profile.name
        reload()
        if let index = DataStore.shared.library.profiles.firstIndex(where: { $0.id == profile.id }) {
            profileTable.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }

    /// Starts a fresh, unsaved profile editor (jump target for
    /// "New Profile…" from the nudge configuration).
    func beginNewProfile() {
        addProfileClicked()
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
            } else {
                cell.stringValue = "\(entry.seconds ?? 0) s \(title)"
            }
        }
        return cell
    }

    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        if tableView == entriesTable, var profile = selectedProfile, row < profile.entries.count {
            let entry = profile.entries[row]
            let exerciseTitle = DataStore.shared.library.exercise(id: entry.exerciseId)?.title ?? "Exercise"
            let alert = NSAlert()
            alert.messageText = "Edit \(exerciseTitle)"
            alert.informativeText = "Amount: plain number = reps (e.g. '10'). Or seconds with 's' (e.g. '30s')."
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
            input.stringValue = entry.reps != nil ? "\(entry.reps!)" : "\(entry.seconds ?? 0)s"
            alert.accessoryView = input
            guard alert.runModal() == .alertFirstButtonReturn else { return false }
            let text = input.stringValue.trimmingCharacters(in: .whitespaces).lowercased()
            if text.hasSuffix("s"), let seconds = Int(text.dropLast()) {
                profile.entries[row] = ProfileEntry(exerciseId: entry.exerciseId, reps: nil, seconds: seconds)
            } else if let reps = Int(text) {
                profile.entries[row] = ProfileEntry(exerciseId: entry.exerciseId, reps: reps, seconds: nil)
            } else {
                return false
            }
            selectedProfile = profile
            reload()
            return false
        }
        return false
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else { return }
        if table == profileTable {
            let row = profileTable.selectedRow
            guard row >= 0, row < profiles.count else { return }
            select(profile: profiles[row])
        }
    }
}
