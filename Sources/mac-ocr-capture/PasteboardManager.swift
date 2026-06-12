import AppKit

protocol PasteboardManagerProtocol {
    func copyToClipboard(_ text: String) -> Bool
    func readFromClipboard() -> String?
}

class PasteboardManager: PasteboardManagerProtocol {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copyToClipboard(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    func readFromClipboard() -> String? {
        return pasteboard.string(forType: .string)
    }
}
