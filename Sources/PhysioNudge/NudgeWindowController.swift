import AppKit

/// Configure Nudges window: list of nudges (profile + schedule), create,
/// edit, delete. Schedule for now: regular interval (typed minutes,
/// default 60); richer schedules (fixed times, hourly windows) come later.
/// Every change saves automatically. "New Profile…" jumps to the Library
/// with a fresh profile editor open; "Trigger Now" fires the nudge
/// immediately for testing.
final class NudgeWindowController: NSWindowController {
    private let tableView = NSTableView()
    private let addButton = NSButton(title: "+", target: nil, action: nil)
    private let deleteButton = NSButton(title: "−", target: nil, action: nil)

    private let nameField = NSTextField()
    private let profilePopup = NSPopUpButton()
    private let newProfileButton = NSButton(title: "New Profile…", target: nil, action: nil)
    private let typePopup = NSPopUpButton()
    private let minutesField = NSTextField()
    private let enabledCheck = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
    private let triggerNowButton = NSButton(title: "Trigger Now", target: nil, action: nil)

    private var selectedNudge: Nudge?

    /// Called when the user wants to create a new profile from here.
    var onNewProfile: (() -> Void)?

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 540, height: 460),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        panel.title = "Configure Nudges"
        super.init(window: panel)
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("nudge"))
        column.title = "Nudges"
        tableView.addTableColumn(column)
        tableView.style = .inset
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 26

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true

        addButton.bezelStyle = .smallSquare
        addButton.action = #selector(addNudge)
        addButton.target = self
        deleteButton.bezelStyle = .smallSquare
        deleteButton.action = #selector(deleteNudge)
        deleteButton.target = self
        deleteButton.isEnabled = false

        let listButtons = NSStackView(views: [addButton, deleteButton])
        listButtons.orientation = .horizontal

        let listStack = NSStackView()
        listStack.orientation = .vertical
        listStack.spacing = 6
        listStack.addArrangedSubview(scroll)
        listStack.addArrangedSubview(listButtons)

        let listBox = NSBox()
        listBox.title = "Nudges"
        listBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        listBox.contentView = listStack

        nameField.placeholderString = "Hourly cervical"
        nameField.target = self
        nameField.action = #selector(fieldChanged)
        minutesField.target = self
        minutesField.action = #selector(fieldChanged)
        minutesField.placeholderString = "60"
        typePopup.addItems(withTitles: ["Regular interval"])

        newProfileButton.bezelStyle = .rounded
        newProfileButton.action = #selector(newProfileClicked)
        newProfileButton.target = self

        enabledCheck.setButtonType(.switch)
        enabledCheck.target = self
        enabledCheck.action = #selector(fieldChanged)
        profilePopup.target = self
        profilePopup.action = #selector(fieldChanged)
        triggerNowButton.bezelStyle = .rounded
        triggerNowButton.action = #selector(triggerNowClicked)
        triggerNowButton.target = self
        triggerNowButton.isEnabled = false

        let editorGrid = NSGridView(views: [
            [NSTextField(labelWithString: "Name:"), nameField],
            [NSTextField(labelWithString: "Profile:"), profilePopup],
            [NSTextField(labelWithString: ""), newProfileButton],
            [NSTextField(labelWithString: "Schedule:"), typePopup],
            [NSTextField(labelWithString: "Minutes between:"), minutesField],
        ])
        editorGrid.rowSpacing = 8
        editorGrid.columnSpacing = 8

        let editorStack = NSStackView()
        editorStack.orientation = .vertical
        editorStack.spacing = 10
        editorStack.addArrangedSubview(editorGrid)
        editorStack.addArrangedSubview(enabledCheck)
        editorStack.addArrangedSubview(triggerNowButton)

        let editorBox = NSBox()
        editorBox.title = "Edit"
        editorBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        editorBox.contentView = editorStack

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(listBox)
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

    @objc private func newProfileClicked() {
        onNewProfile?()
    }

    @objc private func addNudge() {
        var nudges = DataStore.shared.nudges
        let newNudge = Nudge(id: UUID().uuidString,
                             name: "New nudge",
                             profileId: DataStore.shared.library.profiles.first?.id ?? "",
                             schedule: Schedule(type: "interval", intervalMinutes: 60,
                                                fromTime: nil, toTime: nil, times: nil),
                             enabled: true)
        nudges.append(newNudge)
        DataStore.shared.update(nudges: nudges)
        reload()
        loadEditor(nudge: newNudge)
        tableView.selectRowIndexes(IndexSet(integer: nudges.count - 1), byExtendingSelection: false)
        (NSApp.delegate as? AppDelegate)?.schedulerDidReschedule()
    }

    @objc private func deleteNudge() {
        guard let nudge = selectedNudge else { return }
        DataStore.shared.update(nudges: DataStore.shared.nudges.filter { $0.id != nudge.id })
        selectedNudge = nil
        reload()
        clearEditor()
        (NSApp.delegate as? AppDelegate)?.schedulerDidReschedule()
    }

    @objc private func fieldChanged() {
        guard var nudge = selectedNudge else { return }
        nudge.name = nameField.stringValue.isEmpty ? "Nudge" : nameField.stringValue
        nudge.profileId = profilePopup.selectedItem?.representedObject as? String ?? nudge.profileId
        nudge.enabled = enabledCheck.state == .on
        let minutes = Int(minutesField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 60
        nudge.schedule = Schedule(type: "interval", intervalMinutes: max(1, minutes),
                                  fromTime: nil, toTime: nil, times: nil)
        DataStore.shared.update(nudges: DataStore.shared.nudges.map { $0.id == nudge.id ? nudge : $0 })
        selectedNudge = nudge
        tableView.reloadData()
        (NSApp.delegate as? AppDelegate)?.schedulerDidReschedule()
    }

    @objc private func triggerNowClicked() {
        (NSApp.delegate as? AppDelegate)?.triggerNudgeNow()
    }

    private func clearEditor() {
        nameField.stringValue = ""
        enabledCheck.state = .off
        triggerNowButton.isEnabled = false
        deleteButton.isEnabled = false
    }

    private func loadEditor(nudge: Nudge) {
        nameField.stringValue = nudge.name
        profilePopup.removeAllItems()
        for profile in DataStore.shared.library.profiles {
            profilePopup.addItem(withTitle: profile.name)
            profilePopup.lastItem?.representedObject = profile.id
        }
        if let index = profilePopup.itemArray.firstIndex(where: {
            ($0.representedObject as? String) == nudge.profileId
        }) {
            profilePopup.selectItem(at: index)
        }
        enabledCheck.state = nudge.enabled ? .on : .off
        typePopup.selectItem(at: 0)
        minutesField.stringValue = "\(nudge.schedule.intervalMinutes ?? 60)"
        triggerNowButton.isEnabled = true
        deleteButton.isEnabled = true
    }

    func reload() {
        tableView.reloadData()
        deleteButton.isEnabled = selectedNudge != nil
        triggerNowButton.isEnabled = selectedNudge != nil
    }
}

extension NudgeWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        DataStore.shared.nudges.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let nudge = DataStore.shared.nudges[row]
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"),
                                      owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        let profileName = DataStore.shared.library.profile(id: nudge.profileId)?.name ?? nudge.profileId
        cell.stringValue = "\(nudge.name) — \(profileName) — \(nudge.schedule.summary())\(nudge.enabled ? "" : " (off)")"
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0, row < DataStore.shared.nudges.count else {
            selectedNudge = nil
            deleteButton.isEnabled = false
            triggerNowButton.isEnabled = false
            return
        }
        let nudge = DataStore.shared.nudges[row]
        selectedNudge = nudge
        loadEditor(nudge: nudge)
    }
}
