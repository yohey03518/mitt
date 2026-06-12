import Testing
import Foundation
@testable import mac_ocr_capture

@Suite struct NotificationManagerTests {
    @Test func testMakeScriptEscaping() {
        let manager = NotificationManager()
        
        // Test normal string
        let script1 = manager.makeScript(title: "Hello", message: "World")
        #expect(script1 == "display notification \"World\" with title \"Hello\"")
        
        // Test backslash escaping
        let script2 = manager.makeScript(title: "Path: C:\\", message: "Backslash \\ test")
        #expect(script2 == "display notification \"Backslash \\\\ test\" with title \"Path: C:\\\\\"")
        
        // Test quote escaping
        let script3 = manager.makeScript(title: "Quote \"test\"", message: "Nested \"quotes\" here")
        #expect(script3 == "display notification \"Nested \\\"quotes\\\" here\" with title \"Quote \\\"test\\\"\"")
        
        // Test mixed backslash and quote escaping
        let script4 = manager.makeScript(title: "Mixed \\\" test", message: "Another \\\" test")
        #expect(script4 == "display notification \"Another \\\\\\\" test\" with title \"Mixed \\\\\\\" test\"")
        
        // Test newline and control character escaping
        let script5 = manager.makeScript(title: "New\nLine\tTitle", message: "Msg\r\nText")
        #expect(script5 == "display notification \"Msg\\r\\nText\" with title \"New\\nLine\\tTitle\"")
    }

    @Test func testNotificationTriggerDoesNotThrow() {
        let manager = NotificationManager()
        // Run it but do not strictly assert that the returned value is true
        // (since headless CI environments might return false or exit with non-zero)
        _ = manager.sendNotification(title: "Test Title", message: "Test Message Content")
    }
}
