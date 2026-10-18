import AppKit

/// Library window with two tabs: Exercises and Profiles.
/// Exercises: simple list + add via text field (Enter or button).
/// Profiles: list + editor (name, entries with per-entry amount);
/// add existing or new exercises, edit amounts, remove entries, save.
final class LibraryWindowController: NSWindowController, NSWindowDelegate {
    private let tabView = NSTabView(tabViewType: .topTabsBezelBorder)

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
        DataStore.shared.library.exercises.removeAll { $0.id == exercise.id }
        DataStore.shared.persistLibrary()
        reload()
    }

    // MARK: - Profiles actions

    @objc private func newProfileClicked() {
        beginNewProfile()
    }

    @objc private fun
  }
}
