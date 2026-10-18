import AppKit

/// Library window: exercises and profiles in a two-tab layout.
/// Exercises tab: live-searchable list on the left, detail editor with
/// image on the right; add/edit share the same editor (autosave).
/// Profiles tab: profile list, entries editor with per-entry amount.
final class LibraryWindowController: NSWindowController, NSWindowDelegate {
    private let tabView: NSTabView = {
        let view = NSTabView()
        view.tabViewType = .topTabsBezelBorder
        return view
    }()

    // Exercises tab
    private let exerciseTable = NSTableView()
    private let searchField = NSSearchField()
    private let addButton = NSButton(title: "Add Exercise", target: nil, action: nil)
    private let detailBox = NSBox()
    private let detailTitleField = NSTextField()
    private let detailDescriptionView = NSTextView()
    private let detailDescriptionScroll = NSScrollView()
    private let detailTypePopup = NSPopUpButton()
    private let detailImageView = NSImageView()
    private let chooseImageButton = NSButton(title: "Choose Image…", target: nil, action: nil)
    private let removeImageButton = NSButton(title: "Remove Image", target: nil, action: nil)
    private let sketchView = ExerciseVisualView()

    // Profiles tab
    private let profileTable = NSTableView()
    private let newProfileButton = NSButton(title: "New Profile", target: nil, action: nil)
    private let profileNameField = NSTextField()
    private let entriesTable = NSTableView()
    private let addEntryButton = NSButton(title: "Add Exercise…", target: nil, action: nil)
    private let editAmountButton = NSButton(title: "Edit Amount…", target: nil, action: nil)
    private let removeEntryButton = NSButton(title: "Remove Entry", target: nil, action: nil)

    private var selectedExerciseId: String?
    private var selectedProfile: Profile?
    private var isSelectingProgrammatically = false

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        panel.title = "Library"
        panel.minSize = NSSize(width: 640, height: 420)
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

        searchField.placeholderString = "Search exercises…"
        searchField.delegate = self
        searchField.action = #selector(searchChanged)
        searchField.target = self

        addButton.bezelStyle = .rounded
        addButton.target = self
        addButton.action = #selector(addExerciseClicked)

        let listHeader = NSStackView(views: [addButton])
        listHeader.orientation = .horizontal
        listHeader.translatesAutoresizingMaskIntoConstraints = false

        let listBox = NSBox()
        listBox.title = "Exercises"
        listBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        listBox.translatesAutoresizingMaskIntoConstraints = false
        listBox.addSubview(searchField)
        listBox.addSubview(scroll)
        listBox.addSubview(listHeader)
        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: listBox.leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: listBox.trailingAnchor, constant: -8),
            searchField.topAnchor.constraint(equalTo: listBox.topAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: listBox.leadingAnchor, constant: 8),
            scroll.trailingAnchor.constraint(equalTo: listBox.trailingAnchor, constant: -8),
            scroll.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scroll.bottomAnchor.constraint(equalTo: listHeader.topAnchor, constant: -8),
            listHeader.leadingAnchor.constraint(equalTo: listBox.leadingAnchor, constant: 8),
            listHeader.bottomAnchor.constraint(equalTo: listBox.bottomAnchor, constant: -8),
        ])

        // Detail editor
        detailBox.title = "Details"
        detailBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        detailBox.translatesAutoresizingMaskIntoConstraints = false

        detailTitleField.placeholderString = "Exercise name"
        detailTitleField.target = self
        detailTitleField.action = #selector(detailChanged)

        detailTypePopup.addItems(withTitles: ExerciseType.allCases.map { $0.displayName })
        detailTypePopup.target = self
        detailTypePopup.action = #selector(detailChanged)

        detailDescriptionView.isRichText = false
        detailDescriptionView.font = NSFont.systemFont(ofSize: 12)
        detailDescriptionView.isEditable = true
        detailDescriptionView.delegate = self
        detailDescriptionScroll.documentView = detailDescriptionView
        detailDescriptionScroll.hasVerticalScroller = true
        detailDescriptionScroll.translatesAutoresizingMaskIntoConstraints = false
        detailDescriptionScroll.borderType = .bezelBorder

        detailImageView.imageScaling = .scaleProportionallyUpOrDown
        detailImageView.translatesAutoresizingMaskIntoConstraints = false
        sketchView.translatesAutoresizingMaskIntoConstraints = false

        chooseImageButton.bezelStyle = .rounded
        chooseImageButton.target = self
        chooseImageButton.action = #selector(chooseImageClicked)
        removeImageButton.bezelStyle = .rounded
        removeImageButton.target = self
        removeImageButton.action = #selector(removeImageClicked)

        let titleRow = NSGridView(views: [
            [NSTextField(labelWithString: "Name:"), detailTitleField],
            [NSTextField(labelWithString: "Type:"), detailTypePopup],
        ])
        titleRow.columnSpacing = 8
        titleRow.rowSpacing = 8
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        detailTitleField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let descriptionLabel = NSTextField(labelWithString: "Description:")
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let imageRow = NSStackView(views: [chooseImageButton, removeImageButton])
        imageRow.orientation = .horizontal
        imageRow.spacing = 8
        imageRow.translatesAutoresizingMaskIntoConstraints = false

        let imageStack = NSStackView()
        imageStack.orientation = .vertical
        imageStack.spacing = 8
        imageStack.translatesAutoresizingMaskIntoConstraints = false
        imageStack.addArrangedSubview(detailImageView)
        imageStack.addArrangedSubview(sketchView)
        imageStack.addArrangedSubview(imageRow)

        detailBox.addSubview(titleRow)
        detailBox.addSubview(descriptionLabel)
        detailBox.addSubview(detailDescriptionScroll)
        detailBox.addSubview(imageStack)
        NSLayoutConstraint.activate([
            titleRow.leadingAnchor.constraint(equalTo: detailBox.leadingAnchor, constant: 8),
            titleRow.trailingAnchor.constraint(equalTo: detailBox.trailingAnchor, constant: -8),
            titleRow.topAnchor.constraint(equalTo: detailBox.topAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: detailBox.leadingAnchor, constant: 8),
            descriptionLabel.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 8),
            detailDescriptionScroll.leadingAnchor.constraint(equalTo: detailBox.leadingAnchor, constant: 8),
            detailDescriptionScroll.trailingAnchor.constraint(equalTo: imageStack.leadingAnchor, constant: -12),
            detailDescriptionScroll.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            detailDescriptionScroll.bottomAnchor.constraint(equalTo: detailBox.bottomAnchor, constant: -8),
            imageStack.trailingAnchor.constraint(equalTo: detailBox.trailingAnchor, constant: -8),
            imageStack.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 12),
            imageStack.bottomAnchor.constraint(lessThanOrEqualTo: detailBox.bottomAnchor, constant: -8),
            detailImageView.heightAnchor.constraint(equalToConstant: 140),
            detailImageView.widthAnchor.constraint(equalToConstant: 140),
            sketchView.heightAnchor.constraint(equalToConstant: 140),
            sketchView.widthAnchor.constraint(equalToConstant: 140),
        ])

        pane.addSubview(listBox)
        pane.addSubview(detailBox)
        NSLayoutConstraint.activate([
            listBox.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            listBox.widthAnchor.constraint(equalTo: pane.widthAnchor, multiplier: 0.40),
            listBox.topAnchor.constraint(equalTo: pane.topAnchor),
            listBox.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
            detailBox.leadingAnchor.constraint(equalTo: listBox.trailingAnchor, constant: 12),
            detailBox.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            detailBox.topAnchor.constraint(equalTo: pane.topAnchor),
            detailBox.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
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
            newProfileButton.trailingAnchor.constraint(lessThanOrEqualTo: profileBox.trailingAnchor, constant: -8),
            newProfileButton.bottomAnchor.constraint(equalTo: profileBox.bottomAnchor, constant: -8),
        ])

        profileNameField.placeholderString = "Profile name"
        profileNameField.translatesAutoresizingMaskIntoConstraints = false
        profileNameField.target = self
        profileNameField.action = #selector(profileNameChanged)

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

        let editorButtons = NSStackView(views: [addEntryButton, editAmountButton, removeEntryButton])
        editorButtons.orientation = .horizontal
        editorButtons.spacing = 8
        editorButtons.translatesAutoresizingMaskIntoConstraints = false

        let editorBox = NSBox()
        editorBox.title = "Profile Editor (changes save automatically)"
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
            editorButtons.trailingAnchor.constraint(lessThanOrEqualTo: editorBox.trailingAnchor, constant: -8),
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

    @objc private func searchChanged() {
        exerciseTable.reloadData()
    }

    @objc private func addExerciseClicked() {
        let exercise = Exercise(id: UUID().uuidString,
                                title: "New Exercise",
                                description: "",
                                type: .mobility,
                                image: nil,
                                visual: nil)
        DataStore.shared.add(exercise: exercise)
        selectedExerciseId = exercise.id
        reload()
        if let index = filteredExercises.firstIndex(where: { $0.id == exercise.id }) {
            exerciseTable.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        detailTitleField.becomeFirstResponder()
    }

    @objc private func detailChanged() {
        guard var exercise = selectedExercise else { return }
        exercise.title = detailTitleField.stringValue.isEmpty ? "Exercise" : detailTitleField.stringValue
        exercise.type = ExerciseType.allCases[detailTypePopup.indexOfSelectedItem]
        DataStore.shared.update(exercise: exercise)
        reload()
    }

    @objc private func chooseImageClicked() {
        guard selectedExercise != nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .gif, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let name = DataStore.shared.importImage(at: url) else { return }
        var exercise = selectedExercise!
        exercise.image = name
        DataStore.shared.update(exercise: exercise)
        reload()
    }

    @objc private func removeImageClicked() {
        guard var exercise = selectedExercise else { return }
        exercise.image = nil
        DataStore.shared.update(exercise: exercise)
        reload()
    }

    // MARK: - Profiles actions

    @objc private func profileNameChanged() {
        guard var profile = selectedProfile else { return }
        profile.name = profileNameField.stringValue.isEmpty ? "Profile" : profileNameField.stringValue
        selectedProfile = profile
        DataStore.shared.update(profile: profile)
        profileTable.reloadData()
    }

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
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: addEntryButton)
    }

    @objc private func entryExercisePicked(_ sender: NSMenuItem) {
        guard let profile = selectedProfile,
              let exerciseId = sender.representedObject as? String else { return }
        var updated = profile
        updated.entries.append(ProfileEntry(exerciseId: exerciseId, reps: nil, seconds: nil))
        selectedProfile = updated
        DataStore.shared.update(profile: updated)
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
        DataStore.shared.update(profile: profile)
        reload()
    }

    @objc private func removeEntryClicked() {
        guard var profile = selectedProfile else { return }
        let row = entriesTable.selectedRow
        guard row >= 0, row < profile.entries.count else { return }
        profile.entries.remove(at: row)
        selectedProfile = profile
        DataStore.shared.update(profile: profile)
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

    private var filteredExercises: [Exercise] {
        let query = searchField.stringValue.lowercased()
        guard !query.isEmpty else { return DataStore.shared.library.exercises }
        return DataStore.shared.library.exercises.filter {
            $0.title.lowercased().contains(query) ||
            $0.description.lowercased().contains(query)
        }
    }

    private var selectedExercise: Exercise? {
        guard let id = selectedExerciseId else { return nil }
        return DataStore.shared.library.exercise(id: id)
    }

    private var profiles: [Profile] { DataStore.shared.library.profiles }

    func reload() {
        exerciseTable.reloadData()
        profileTable.reloadData()
        entriesTable.reloadData()

        // Exercise detail
        let exercise = selectedExercise
        let hasExercise = exercise != nil
        [detailTitleField, detailTypePopup, detailDescriptionView,
         chooseImageButton, removeImageButton].forEach { $0.isEnabled = hasExercise }
        if let exercise = exercise {
            detailTitleField.stringValue = exercise.title
            detailTypePopup.selectItem(withTitle: (exercise.type ?? .mobility).displayName)
            if detailDescriptionView.string != exercise.description {
                detailDescriptionView.string = exercise.description
            }
            if let imageURL = DataStore.shared.imageURL(for: exercise.image),
               let image = NSImage(contentsOf: imageURL) {
                detailImageView.image = image
                sketchView.configure(kind: .none)
                sketchView.isHidden = true
                detailImageView.isHidden = false
            } else {
                detailImageView.image = nil
                sketchView.configure(kind: ExerciseVisualView.Kind(rawValue: exercise.visual ?? "none") ?? .none)
                sketchView.isHidden = false
                detailImageView.isHidden = true
            }
        } else {
            detailTitleField.stringValue = ""
            detailDescriptionView.string = ""
            detailImageView.image = nil
            sketchView.configure(kind: .none)
        }

        // Profiles
        let hasProfile = selectedProfile != nil
        addEntryButton.isEnabled = hasProfile
        editAmountButton.isEnabled = hasProfile
        removeEntryButton.isEnabled = hasProfile
        if let profile = selectedProfile {
            profileNameField.stringValue = profile.name
        }
    }

    func select(profile: Profile) {
        isSelectingProgrammatically = true
        selectedProfile = profile
        reload()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profileTable.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        isSelectingProgrammatically = false
    }

    func beginNewProfile() {
        let profile = Profile(id: UUID().uuidString, name: "New Profile", entries: [])
        DataStore.shared.update(profile: profile)
        selectedProfile = profile
        reload()
        tabView.selectTabViewItem(at: 1)
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profileTable.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }
}

extension LibraryWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == exerciseTable {
            return filteredExercises.count
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
            let exercise = filteredExercises[row]
            cell.stringValue = exercise.title
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
        if table == exerciseTable {
            let row = exerciseTable.selectedRow
            guard row >= 0, row < filteredExercises.count else {
                selectedExerciseId = nil
                reload()
                return
            }
            selectedExerciseId = filteredExercises[row].id
            reload()
        } else if table == profileTable {
            if isSelectingProgrammatically { return }
            let row = profileTable.selectedRow
            guard row >= 0, row < profiles.count else { return }
            select(profile: profiles[row])
        }
    }
}

extension LibraryWindowController: NSSearchFieldDelegate, NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if notification.object as? NSTextView == detailDescriptionView {
            guard var exercise = selectedExercise else { return }
            exercise.description = detailDescriptionView.string
            DataStore.shared.update(exercise: exercise)
        }
    }
}
