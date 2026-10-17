import AppKit

/// Library window: exercises and profiles; select an exercise and do it
/// now via the Do Now button (key user's requested workflow).
final class LibraryWindowController: NSWindowController {
    private let tableView = NSTableView()
    private let profileTable = NSTableView()
    private let doNowButton = NSButton(title: "Do Now", target: nil, action: nil)

    private var selectedExerciseId: String?
    var onDoNow: ((LibraryExercise) -> Void)?

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        panel.title = "Library"
        super.init(window: panel)
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        let exerciseColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("exercise"))
        exerciseColumn.title = "Exercise"
        tableView.addTableColumn(exerciseColumn)
        tableView.style = .inset
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 26

        let profileColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("profile"))
        profileColumn.title = "Profile"
        profileTable.addTableColumn(profileColumn)
        profileTable.style = .inset
        profileTable.delegate = self
        profileTable.dataSource = self
        profileTable.rowHeight = 26

        let exerciseScroll = NSScrollView()
        exerciseScroll.documentView = tableView
        exerciseScroll.hasVerticalScroller = true

        let profileScroll = NSScrollView()
        profileScroll.documentView = profileTable
        profileScroll.hasVerticalScroller = true

        let exerciseBox = titledBox(title: "Exercises", view: exerciseScroll)
        let profileBox = titledBox(title: "Profiles", view: profileScroll)

        doNowButton.bezelStyle = .rounded
        doNowButton.action = #selector(doNowClicked)
        doNowButton.target = self
        doNowButton.isEnabled = false

        let info = NSTextField(wrappingLabelWithString:
            "Select an exercise and click Do Now to nudge yourself immediately. Edit library.json in ~/Library/Application Support/PhysioNudge to add your own exercises and profiles.")
        info.font = NSFont.systemFont(ofSize: 11)
        info.textColor = .secondaryLabelColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(exerciseBox)
        stack.addArrangedSubview(profileBox)
        stack.addArrangedSubview(info)
        stack.addArrangedSubview(doNowButton)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    private func titledBox(title: String, view: NSView) -> NSView {
        let box = NSBox(title: title)
        box.titleFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        box.contentView = view
        box.boxType = .secondary
        return box
    }

    @objc private func doNowClicked() {
        guard let id = selectedExerciseId,
              let exercise = DataStore.shared.library.exercise(id: id) else { return }
        onDoNow?(exercise)
    }

    func reload() {
        tableView.reloadData()
        profileTable.reloadData()
    }

    private var exercises: [LibraryExercise] { DataStore.shared.library.exercises }
    private var profiles: [Profile] { DataStore.shared.library.profiles }
}

extension LibraryWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView == self.tableView ? exercises.count : profiles.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"),
                                      owner: self) as? NSTextField
            ?? NSTextField(labelWithString: "")
        if tableView == self.tableView {
            cell.stringValue = exercises[row].title
        } else {
            cell.stringValue = profiles[row].name
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView, table == tableView else { return }
        let row = table.selectedRow
        guard row >= 0, row < exercises.count else {
            selectedExerciseId = nil
            doNowButton.isEnabled = false
            return
        }
        selectedExerciseId = exercises[row].id
        doNowButton.isEnabled = true
    }
}
