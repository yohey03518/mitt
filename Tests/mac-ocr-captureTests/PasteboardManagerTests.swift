import Testing
import Foundation
import AppKit
@testable import mac_ocr_capture

@Suite struct PasteboardManagerTests {
    @Test func testCopyToClipboardAndReadBack() {
        let manager = PasteboardManager(pasteboard: .withUniqueName())
        let testString = "Hello OCR Clipboard Test \(UUID().uuidString)"
        
        let success = manager.copyToClipboard(testString)
        #expect(success, "Should successfully copy to clipboard")
        
        let retrieved = manager.readFromClipboard()
        #expect(retrieved == testString, "Retrieved clipboard text should match the copied text")
    }
}
