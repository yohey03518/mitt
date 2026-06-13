import Foundation

func main() async -> Int32 {
    let tempFileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("ocr_screenshot_temp_\(UUID().uuidString).png")
    
    defer {
        try? FileManager.default.removeItem(at: tempFileURL)
    }
    
    do {
        let captureManager = CaptureManager()
        let ocrManager = OCRManager()
        let pasteboardManager = PasteboardManager()
        let notificationManager = NotificationManager()
        
        print("Starting selection capture...")
        let exitCode = try captureManager.captureInteractive(outputPath: tempFileURL.path)
        if exitCode != 0 {
            print("Capture cancelled or failed. Exiting.")
            return 0
        }
        
        guard FileManager.default.fileExists(atPath: tempFileURL.path) else {
            print("Screenshot file not found.")
            return 1
        }
        
        print("Performing OCR...")
        let languages = LanguageParser.parseLanguages(from: CommandLine.arguments)
        let recognizedText = try await ocrManager.recognizeText(fromImageAt: tempFileURL, languages: languages)
        
        let trimmedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            _ = notificationManager.sendNotification(
                title: "OCR Screenshot",
                message: "No text was detected in the selected area."
            )
            print("No text detected.")
        } else {
            let copySuccess = pasteboardManager.copyToClipboard(trimmedText)
            if copySuccess {
                // Create a short preview of the text for the notification (replace newlines with spaces)
                let previewLength = 40
                let cleanedPreview = trimmedText.replacingOccurrences(of: "\n", with: " ")
                let previewText = cleanedPreview.count > previewLength
                    ? String(cleanedPreview.prefix(previewLength)) + "..."
                    : cleanedPreview
                
                _ = notificationManager.sendNotification(
                    title: "OCR Screenshot",
                    message: "Copied: \"\(previewText)\""
                )
                print("OCR Text successfully copied to clipboard.")
            } else {
                _ = notificationManager.sendNotification(
                    title: "OCR Screenshot",
                    message: "Failed to copy text to clipboard."
                )
                print("Clipboard write failed.")
            }
        }
        return 0
    } catch {
        let notificationManager = NotificationManager()
        _ = notificationManager.sendNotification(
            title: "OCR Screenshot Error",
            message: error.localizedDescription
        )
        print("OCR Error: \(error.localizedDescription)")
        return 1
    }
}

let exitStatus = await main()
exit(exitStatus)
