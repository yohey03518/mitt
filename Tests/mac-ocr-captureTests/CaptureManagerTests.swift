import Testing
import Foundation
@testable import mac_ocr_capture

@Suite struct CaptureManagerTests {
    @Test func testCaptureInteractiveConfiguresProcessCorrectly() throws {
        var ranURL: URL?
        var ranArguments: [String]?
        
        let manager = CaptureManager { url, args in
            ranURL = url
            ranArguments = args
            return 0 // Mock successful execution
        }
        
        let exitCode = try manager.captureInteractive(outputPath: "/tmp/test.png")
        
        #expect(exitCode == 0)
        #expect(ranURL?.path == "/usr/sbin/screencapture")
        #expect(ranArguments == ["-i", "-r", "/tmp/test.png"])
    }
}
