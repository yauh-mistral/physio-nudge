import AppKit

/// Settings window: overlay position (corner), and future notifier options.
final class SettingsWindowController: NSWindowController {
    private let cornerPopup = NSPopUpButton()

    init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
                            styleMask: [.titled, .closable, .miniaturizable],
                            backing: .buffered, defer: false)
        panel.title = "Settings"
        super.init(window: panel)
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        let cornerLabel = NSTextField(labelWithString: "Overlay position:")
        cornerPopup.addItems(withTitles: OverlayCorner.allCases.map { $0.rawValue })
        cornerPopup.action = #selector(cornerChanged)
        cornerPopup.target = self
        cornerPopup.selectItem(withTitle: DataStore.shared.currentCorner.rawValue)

        let grid = NSGridView(views: [[cornerLabel, cornerPopup]])
        grid.rowSpacing = 10
        grid.columnSpacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false

        let info = NSTextField(wrappingLabelWithString:
            "The nudge appears in the selected screen corner and never steals focus.")
        info.font = NSFont.systemFont(ofSize: 11)
        info.textColor = .secondaryLabelColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(grid)
        stack.addArrangedSubview(info)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
        ])
    }

    @objc private func cornerChanged() {
        guard let corner = OverlayCorner.allCases.first(where: {
            $0.rawValue == cornerPopup.titleOfSelectedItem
        }) else { return }
        DataStore.shared.update(corner: corner)
    }
}
