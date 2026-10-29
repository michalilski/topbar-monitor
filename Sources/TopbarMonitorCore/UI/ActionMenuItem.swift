import AppKit

final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: NSAttributedString, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title.string, action: #selector(fire), keyEquivalent: key)
        target = self
        attributedTitle = title
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func fire() {
        handler()
    }
}
