import AppKit

/// Configure Nudges window: list of nudges (profile + schedule), create,
/// edit, delete. Schedules: interval, hourly window, fixed times.
final class NudgeWindowController: NSWindowController {
    private let tableView = NSTableView()
    private let addButton = NSButton(title: "+", target: nil, action: nil)
    private let deleteButton = NSButton(title: "−", target: nil, action: nil)

    private let nameField = NSTextField()
    private let profilePopup = NSPopUpButton()
    private let typePopup = NSPopUpButton()
    private let intervalPopup = NSPopUpButton()
    private let fromField = NSTextField()
    private let toField = NSTextField()
    private let timesField = NSTextField()
    private let enabledCheck = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
    private let applyButton = NSButton(title: "Apply", target: nil, action: nil)

    private let intervalMinutesOptions = [5, 10, 15, 30, 45, 60, 90, 120]
    private var selectedNudge: Nudge?

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
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

        let listBox = NSBox(title: "Nudges")
        listBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        listBox.contentView = listStack
        listBox.boxType = .secondary

        nameField.placeholderString = "Hourly cervical"
        fromField.placeholderString = "08:00"
        toField.placeholderString = "16:00"
        timesField.placeholderString = "10:00, 14:00, 18:00"
        typePopup.addItems(withTitles: ["Every N minutes", "Hourly between", "At fixed times"])
        intervalPopup.addItems(withTitles: intervalMinutesOptions.map { "\($0) min" })

        enabledCheck.setButtonType(.switch)
        applyButton.bezelStyle = .rounded
        applyButton.action = #selector(applyChanges)
        applyButton.target = self
        applyButton.isEnabled = false

        let editorGrid = NSGridView(views: [
            [NSTextField(labelWithString: "Name:"), nameField],
            [NSTextField(labelWithString: "Profile:"), profilePopup],
            [NSTextField(labelWithString: "Schedule:"), typePopup],
            [NSTextField(labelWithString: "Minutes:"), intervalPopup],
            [NSTextField(labelWithString: "From:"), fromField],
            [NSTextField(labelWithString: "To:"), toField],
            [NSTextField(labelWithString: "Times:"), timesField],
        ])
        editorGrid.rowSpacing = 8
        editorGrid.columnSpacing = 8

        let editorStack = NSStackView()
        editorStack.orientation = .vertical
        editorStack.spacing = 10
        editorStack.addArrangedSubview(editorGrid)
        editorStack.addArrangedSubview(enabledCheck)
        editorStack.addArrangedSubview(applyButton)

        let editorBox = NSBox(title: "Edit")
        editorBox.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        editorBox.contentView = editorStack
        editorBox.boxType = .secondary

        let split = NSSplitView()
        split.vertical = true
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

        showScheduleFields()
    }

    private func showScheduleFields() {
        switch typePopup.indexOfSelectedItem {
        case 0:
            intervalPopup.isHidden = false
            fromField.isHidden = true
            toField.isHidden = true
            timesField.isHidden = true
        case 1:
            intervalPopup.isHidden = true
            fromField.isHidden = false
            toField.isHidden = false
            timesField.isHidden = true
        default:
            intervalPopup.isHidden = true
            fromField.isHidden = true
            toField.isHidden = true
            timesField.isHidden = false
        }
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

    @objc private func applyChanges() {
        guard var nudge = selectedNudge else { return }
        nudge.name = nameField.stringValue.isEmpty ? "Nudge" : nameField.stringValue
        nudge.profileId = profilePopup.selectedItem?.representedObject as? String ?? nudge.profileId
        nudge.enabled = enabledCheck.state == .on
        switch typePopup.indexOfSelectedItem {
        case 0:
            let minutes = intervalMinutesOptions[intervalPopup.indexOfSelectedItem]
            nudge.schedule = Schedule(type: "interval", intervalMinutes: minutes,
                                      fromTime: nil, toTime: nil, times: nil)
        case 1:
            nudge.schedule = Schedule(type: "hourly", intervalMinutes: nil,
                                      fromTime: fromField.stringValue, toTime: toField.stringValue, times: nil)
        default:
            let times = timesField.stringValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            nudge.schedule = Schedule(type: "at", intervalMinutes: nil,
                                     fromTime: nil, toTime: nil, times: times)
        }
        DataStore.shared.update(nudges: DataStore.shared.nudges.map { $0.id == nudge.id ? nudge : $0 })
        selectedNudge = nudge
        reload()
        (NSApp.delegate as? AppDelegate)?.schedulerDidReschedule()
    }

    private func clearEditor() {
        nameField.stringValue = ""
        enabledCheck.state = .off
        applyButton.isEnabled = false
        deleteButton.isEnabled = false
    }

    private func loadEditor(nudge: Nudge) {
        nameField.stringValue = nudge.name
        profilePopup.removeAllItems()
        for profile in DataStore.shared.library.profiles {
            profilePopup.addItem(withTitle: profile.name)
            profilePopup.lastItem?.representedObject = profile.id
        }
        profilePopup.selectItem(withRepresentedObject: nudge.profileId)
        enabledCheck.state = nudge.enabled ? .on : .off
        switch nudge.schedule.type {
        case "interval":
            typePopup.selectItem(at: 0)
            if let index = intervalMinutesOptions.firstIndex(of: nudge.schedule.intervalMinutes ?? 60) {
                intervalPopup.selectItem(at: index)
            }
        case "hourly":
            typePopup.selectItem(at: 1)
            fromField.stringValue = nudge.schedule.fromTime ?? ""
            toField.stringValue = nudge.schedule.toTime ?? ""
        case "at":
            typePopup.selectItem(at: 2)
            timesField.stringValue = (nudge.schedule.times ?? []).joined(separator: ", ")
        default:
            typePopup.selectItem(at: 0)
        }
        showScheduleFields()
        applyButton.isEnabled = true
        deleteButton.isEnabled = true
    }

    func reload() {
        tableView.reloadData()
        deleteButton.isEnabled = selectedNudge != nil
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
            applyButton.isEnabled = false
            return
        }
        let nudge = DataStore.shared.nudges[row]
        selectedNudge = nudge
        loadEditor(nudge: nudge)
    }
}
