import Testing
import CoreGraphics
import ImageIO
import Foundation
import AppKit
import UniformTypeIdentifiers
@testable import mac_ocr_capture

@Suite struct OCRManagerTests {
    @Test func testOCROnGeneratedImage() async throws {
        let textToRender = "HELLO OCR"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_ocr_render_\(UUID().uuidString).png")
        
        // Generate a PNG image with text
        let size = CGSize(width: 400, height: 100)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            Issue.record("Failed to create CGContext")
            return
        }
        
        // Background: white
        context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: textToRender, attributes: attributes)
        
        // Draw the string inside the graphics context
        NSGraphicsContext.saveGraphicsState()
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
        
        attributedString.draw(in: CGRect(x: 0, y: 30, width: size.width, height: size.height - 30))
        
        NSGraphicsContext.restoreGraphicsState()
        
        guard let cgImage = context.makeImage() else {
            Issue.record("Failed to make CGImage")
            return
        }
        
        // UTType.png requires UniformTypeIdentifiers (macOS 11+)
        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            Issue.record("Failed to create image destination")
            return
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            Issue.record("Failed to finalize image destination")
            return
        }
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Test OCR on the saved file
        let manager = OCRManager()
        let text = try await manager.recognizeText(fromImageAt: tempURL)
        
        #expect(text.contains(textToRender), "OCR output '\(text)' should contain rendered string '\(textToRender)'")
    }
}
