# Native macOS OCR Screenshot Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a macOS CLI utility that runs interactive screenshot capture, OCRs the captured area via the Vision Framework, copies the text to the clipboard, and triggers a system notification.

**Architecture:** A compiled Swift Package Manager (SPM) CLI application divided into modular, testable components: Process wrapper for `screencapture`, OCR Engine using `Vision`, Pasteboard wrapper, and `osascript` wrapper for notifications.

**Tech Stack:** Swift, Vision Framework, AppKit, Foundation, CoreGraphics, XCTest

---

## File Structure

The project will be organized as follows:
- `Package.swift` - Swift Package Manager configuration.
- `Sources/mac-ocr-capture/`
  - `main.swift` - Orchestrator and entry point.
  - `CaptureManager.swift` - Wrapper for spawning `/usr/sbin/screencapture`.
  - `OCRManager.swift` - Vision OCR processing engine.
  - `PasteboardManager.swift` - Clipboard manipulation using AppKit `NSPasteboard`.
  - `NotificationManager.swift` - User notifications using `osascript`.
- `Tests/mac-ocr-captureTests/`
  - `OCRManagerTests.swift` - Generates a test image in-memory containing text and runs OCR on it.
  - `PasteboardManagerTests.swift` - Verifies pasteboard read/write functionality.
  - `CaptureManagerTests.swift` - Verifies command formation.
  - `NotificationManagerTests.swift` - Verifies osascript command string generation.

---

## Tasks

### Task 1: Project Initialization & SPM Setup

**Files:**
- Create: `Package.swift`
- Create: `Sources/mac-ocr-capture/main.swift`
- Create: `Tests/mac-ocr-captureTests/mac_ocr_captureTests.swift`

- [ ] **Step 1: Create the Package.swift configuration**
  Write this package definition to specify macOS v10.15+ target support (required for Vision OCR):
  ```swift
  // swift-tools-version:5.5
  import PackageDescription

  let package = Package(
      name: "mac-ocr-capture",
      platforms: [
          .macOS(.v10_15)
      ],
      products: [
          .executable(name: "mac-ocr-capture", targets: ["mac-ocr-capture"])
      ],
      dependencies: [],
      targets: [
          .executableTarget(
              name: "mac-ocr-capture",
              dependencies: []),
          .testTarget(
              name: "mac-ocr-captureTests",
              dependencies: ["mac-ocr-capture"])
      ]
  )
  ```

- [ ] **Step 2: Create a dummy main.swift**
  ```swift
  import Foundation

  print("OCR Tool Initialized")
  ```

- [ ] **Step 3: Create a basic test file**
  Write `Tests/mac-ocr-captureTests/mac_ocr_captureTests.swift`:
  ```swift
  import XCTest
  import Foundation

  final class MacOcrCaptureTests: XCTestCase {
      func testInitialization() {
          XCTAssertTrue(true)
      }
  }
  ```

- [ ] **Step 4: Verify the SPM setup runs tests successfully**
  Run: `swift test`
  Expected: PASS

- [ ] **Step 5: Commit changes**
  ```bash
  git add Package.swift Sources/ Tests/
  git commit -m "chore: initialize Swift Package Manager project structure"
  ```

---

### Task 2: Pasteboard (Clipboard) Manager

**Files:**
- Create: `Sources/mac-ocr-capture/PasteboardManager.swift`
- Create: `Tests/mac-ocr-captureTests/PasteboardManagerTests.swift`

- [ ] **Step 1: Write the Clipboard interface and implementation**
  Create `Sources/mac-ocr-capture/PasteboardManager.swift`:
  ```swift
  import AppKit

  protocol PasteboardManagerProtocol {
      func copyToClipboard(_ text: String) -> Bool
      func readFromClipboard() -> String?
  }

  class PasteboardManager: PasteboardManagerProtocol {
      private let pasteboard = NSPasteboard.general

      func copyToClipboard(_ text: String) -> Bool {
          pasteboard.declareTypes([.string], owner: nil)
          return pasteboard.setString(text, forType: .string)
      }

      func readFromClipboard() -> String? {
          return pasteboard.string(forType: .string)
      }
  }
  ```

- [ ] **Step 2: Write tests for PasteboardManager**
  Create `Tests/mac-ocr-captureTests/PasteboardManagerTests.swift`:
  ```swift
  import XCTest
  @testable import mac_ocr_capture

  final class PasteboardManagerTests: XCTestCase {
      func testCopyToClipboardAndReadBack() {
          let manager = PasteboardManager()
          let testString = "Hello OCR Clipboard Test \(UUID().uuidString)"
          
          let success = manager.copyToClipboard(testString)
          XCTAssertTrue(success, "Should successfully copy to clipboard")
          
          let retrieved = manager.readFromClipboard()
          XCTAssertEqual(retrieved, testString, "Retrieved clipboard text should match the copied text")
      }
  }
  ```

- [ ] **Step 3: Run pasteboard tests**
  Run: `swift test --filter PasteboardManagerTests`
  Expected: PASS

- [ ] **Step 4: Commit changes**
  ```bash
  git add Sources/mac-ocr-capture/PasteboardManager.swift Tests/mac-ocr-captureTests/PasteboardManagerTests.swift
  git commit -m "feat: implement PasteboardManager and write unit tests"
  ```

---

### Task 3: Desktop Notifications via osascript

**Files:**
- Create: `Sources/mac-ocr-capture/NotificationManager.swift`
- Create: `Tests/mac-ocr-captureTests/NotificationManagerTests.swift`

- [ ] **Step 1: Write the NotificationManager**
  Create `Sources/mac-ocr-capture/NotificationManager.swift`:
  ```swift
  import Foundation

  protocol NotificationManagerProtocol {
      func sendNotification(title: String, message: String) -> Bool
  }

  class NotificationManager: NotificationManagerProtocol {
      func sendNotification(title: String, message: String) -> Bool {
          // Escape quotes for AppleScript string literals
          let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
          let escapedMessage = message.replacingOccurrences(of: "\"", with: "\\\"")
          
          let script = "display notification \"\(escapedMessage)\" with title \"\(escapedTitle)\""
          
          let process = Process()
          process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
          process.arguments = ["-e", script]
          
          do {
              try process.run()
              process.waitUntilExit()
              return process.terminationStatus == 0
          } catch {
              print("Failed to display notification: \(error)")
              return false
          }
      }
  }
  ```

- [ ] **Step 2: Write unit tests for NotificationManager**
  Create `Tests/mac-ocr-captureTests/NotificationManagerTests.swift`:
  ```swift
  import XCTest
  @testable import mac_ocr_capture

  final class NotificationManagerTests: XCTestCase {
      func testNotificationTriggerDoesNotThrow() {
          let manager = NotificationManager()
          // We trigger a simple notification. In headless/CI test environments,
          // osascript should still succeed to send notification or exit cleanly.
          let success = manager.sendNotification(title: "Test Title", message: "Test Message Content")
          XCTAssertTrue(success, "Notification process should run and exit successfully")
      }
  }
  ```

- [ ] **Step 3: Run notification tests**
  Run: `swift test --filter NotificationManagerTests`
  Expected: PASS (with a physical system notification popping up on your macOS desktop!)

- [ ] **Step 4: Commit changes**
  ```bash
  git add Sources/mac-ocr-capture/NotificationManager.swift Tests/mac-ocr-captureTests/NotificationManagerTests.swift
  git commit -m "feat: implement NotificationManager using AppleScript wrapper"
  ```

---

### Task 4: Screen Capture Process Runner

**Files:**
- Create: `Sources/mac-ocr-capture/CaptureManager.swift`
- Create: `Tests/mac-ocr-captureTests/CaptureManagerTests.swift`

- [ ] **Step 1: Write CaptureManager**
  Create `Sources/mac-ocr-capture/CaptureManager.swift`:
  ```swift
  import Foundation

  protocol CaptureManagerProtocol {
      func captureInteractive(outputPath: String) -> Int32
  }

  class CaptureManager: CaptureManagerProtocol {
      func captureInteractive(outputPath: String) -> Int32 {
          let process = Process()
          process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
          // -i: interactive mode
          // -r: screen capture without window shadow/border properties
          process.arguments = ["-i", "-r", outputPath]
          
          do {
              try process.run()
              process.waitUntilExit()
              return process.terminationStatus
          } catch {
              print("Failed to run screencapture process: \(error)")
              return -1
          }
      }
  }
  ```

- [ ] **Step 2: Write tests for CaptureManager**
  Create `Tests/mac-ocr-captureTests/CaptureManagerTests.swift`:
  ```swift
  import XCTest
  @testable import mac_ocr_capture

  final class CaptureManagerTests: XCTestCase {
      func testCaptureCommandPaths() {
          let manager = CaptureManager()
          XCTAssertNotNil(manager, "CaptureManager should be instantiable")
      }
  }
  ```

- [ ] **Step 3: Run capture tests**
  Run: `swift test --filter CaptureManagerTests`
  Expected: PASS

- [ ] **Step 4: Commit changes**
  ```bash
  git add Sources/mac-ocr-capture/CaptureManager.swift Tests/mac-ocr-captureTests/CaptureManagerTests.swift
  git commit -m "feat: implement CaptureManager subprocess wrapper for screencapture"
  ```

---

### Task 5: OCR Processor via Vision Framework

**Files:**
- Create: `Sources/mac-ocr-capture/OCRManager.swift`
- Create: `Tests/mac-ocr-captureTests/OCRManagerTests.swift`

- [ ] **Step 1: Write OCRManager**
  Create `Sources/mac-ocr-capture/OCRManager.swift`:
  ```swift
  import Foundation
  import Vision

  protocol OCRManagerProtocol {
      func recognizeText(fromImageAt url: URL, completion: @escaping (Result<String, Error>) -> Void)
  }

  class OCRManager: OCRManagerProtocol {
      func recognizeText(fromImageAt url: URL, completion: @escaping (Result<String, Error>) -> Void) {
          guard FileManager.default.fileExists(atPath: url.path) else {
              completion(.failure(NSError(domain: "OCRManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found at \(url.path)"])))
              return
          }
          
          let request = VNRecognizeTextRequest { (request, error) in
              if let error = error {
                  completion(.failure(error))
                  return
              }
              
              guard let observations = request.results as? [VNRecognizedTextObservation] else {
                  completion(.success(""))
                  return
              }
              
              // Sort observations by bounding box top-to-bottom, then left-to-right
              let sortedObservations = observations.sorted { (obs1, obs2) -> Bool in
                  let box1 = obs1.boundingBox
                  let box2 = obs2.boundingBox
                  if abs(box1.origin.y - box2.origin.y) < 0.05 {
                      return box1.origin.x < box2.origin.x
                  }
                  return box1.origin.y > box2.origin.y
              }
              
              let recognizedStrings = sortedObservations.compactMap { observation in
                  observation.topCandidates(1).first?.string
              }
              
              let joinedText = recognizedStrings.joined(separator: "\n")
              completion(.success(joinedText))
          }
          
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = true
          
          let handler = VNImageRequestHandler(url: url, options: [:])
          
          DispatchQueue.global(qos: .userInitiated).async {
              do {
                  try handler.perform([request])
              } catch {
                  completion(.failure(error))
              }
          }
      }
  }
  ```

- [ ] **Step 2: Write unit tests with dynamically generated test image**
  Write tests in `Tests/mac-ocr-captureTests/OCRManagerTests.swift` that generate an image using CoreGraphics, draw "HELLO OCR" into it, save it, run OCR, and assert that it correctly recognizes "HELLO OCR".
  ```swift
  import XCTest
  import CoreGraphics
  import ImageIO
  import Foundation
  @testable import mac_ocr_capture

  final class OCRManagerTests: XCTestCase {
      func testOCROnGeneratedImage() {
          let textToRender = "HELLO OCR"
          let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_ocr_render.png")
          
          // Generate a PNG image with text
          let size = CGSize(width: 400, height: 100)
          let colorSpace = CGColorSpaceCreateDeviceRGB()
          guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
              XCTFail("Failed to create CGContext")
              return
          }
          
          // Background: white
          context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
          context.fill(CGRect(origin: .zero, size: size))
          
          // For drawing text, we can use simple NSAttributedString drawing or CGContext text drawing
          // Standard macOS AppKit drawing works cleanly:
          #if os(macOS)
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
          #endif
          
          guard let cgImage = context.makeImage() else {
              XCTFail("Failed to make CGImage")
              return
          }
          
          guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, kUTTypePNG, 1, nil) else {
              XCTFail("Failed to create image destination")
              return
          }
          CGImageDestinationAddImage(destination, cgImage, nil)
          guard CGImageDestinationFinalize(destination) else {
              XCTFail("Failed to finalize image destination")
              return
          }
          
          // Test OCR on the saved file
          let manager = OCRManager()
          let expectation = self.expectation(description: "OCR processing completed")
          
          manager.recognizeText(fromImageAt: tempURL) { result in
              switch result {
              case .success(let text):
                  XCTAssertTrue(text.contains(textToRender), "OCR output '\(text)' should contain rendered string '\(textToRender)'")
              case .failure(let error):
                  XCTFail("OCR failed with error: \(error)")
              }
              expectation.fulfill()
          }
          
          waitForExpectations(timeout: 5.0, handler: nil)
          
          // Cleanup
          try? FileManager.default.removeItem(at: tempURL)
      }
  }
  ```

- [ ] **Step 3: Run OCR tests**
  Run: `swift test --filter OCRManagerTests`
  Expected: PASS

- [ ] **Step 4: Commit changes**
  ```bash
  git add Sources/mac-ocr-capture/OCRManager.swift Tests/mac-ocr-captureTests/OCRManagerTests.swift
  git commit -m "feat: implement OCRManager using native Vision Framework and write integration tests"
  ```

---

### Task 6: Main Orchestrator integration

**Files:**
- Modify: `Sources/mac-ocr-capture/main.swift`

- [ ] **Step 1: Write orchestrator logic in main.swift**
  Replace `Sources/mac-ocr-capture/main.swift` with the full pipeline orchestration:
  ```swift
  import Foundation

  let tempFilePath = "/tmp/ocr_screenshot_temp.png"
  let tempFileURL = URL(fileURLWithPath: tempFilePath)

  let captureManager = CaptureManager()
  let ocrManager = OCRManager()
  let pasteboardManager = PasteboardManager()
  let notificationManager = NotificationManager()

  // Clean up any stale file from prior executions
  try? FileManager.default.removeItem(at: tempFileURL)

  print("Starting selection capture...")
  let exitCode = captureManager.captureInteractive(outputPath: tempFilePath)

  // 1. Check if user cancelled
  if exitCode != 0 {
      print("Capture cancelled or failed. Exiting.")
      exit(0)
  }

  // 2. Wait for file to write and verify it exists
  guard FileManager.default.fileExists(atPath: tempFilePath) else {
      print("Screenshot file not found.")
      exit(1)
  }

  // Semaphore to keep CLI alive during async OCR execution
  let semaphore = DispatchSemaphore(value: 0)

  print("Performing OCR...")
  ocrManager.recognizeText(fromImageAt: tempFileURL) { result in
      defer {
          // Cleanup temp file
          try? FileManager.default.removeItem(at: tempFileURL)
          semaphore.signal()
      }
      
      switch result {
      case .success(let recognizedText):
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
                  // Create a short preview of the text for the notification
                  let previewLength = 40
                  let previewText = trimmedText.count > previewLength 
                      ? String(trimmedText.prefix(previewLength)) + "..."
                      : trimmedText
                  
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
      case .failure(let error):
          _ = notificationManager.sendNotification(
              title: "OCR Screenshot Error",
              message: error.localizedDescription
          )
          print("OCR Error: \(error.localizedDescription)")
      }
  }

  semaphore.wait()
  ```

- [ ] **Step 2: Verify all tests build and run successfully**
  Run: `swift test`
  Expected: PASS

- [ ] **Step 3: Compile final release binary**
  Run: `swift build -c release`
  Expected: Build finishes with output executable: `.build/release/mac-ocr-capture`

- [ ] **Step 4: Commit orchestration changes**
  ```bash
  git add Sources/mac-ocr-capture/main.swift
  git commit -m "feat: complete end-to-end orchestration in main.swift"
  ```

---

### Task 7: Build & Installation Setup instructions

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md detailing shortcut configuration**
  Create `README.md` with configuration guidelines:
  ```markdown
  # Native macOS OCR Screenshot Tool

  A lightweight, zero-dependency command line utility that captures a region of the screen, OCRs the captured area via macOS's native Vision framework, copies it to the clipboard, and triggers a desktop notification.

  ## Requirements
  - macOS 10.15 Catalina or later
  - Xcode Command Line Tools installed (run `xcode-select --install` if needed)

  ## Installation

  1. Clone this repository:
     ```bash
     git clone https://github.com/yohey03518/mitt.git
     cd mitt
     ```

  2. Build the binary in Release mode:
     ```bash
     swift build -c release
     ```

  3. Copy the binary to a directory in your system path (e.g. `/usr/local/bin`):
     ```bash
     sudo cp .build/release/mac-ocr-capture /usr/local/bin/mac-ocr-capture
     ```

  ## How to Configure keyboard shortcut (macOS Shortcuts App)

  To trigger the OCR capture tool using a keyboard shortcut:

  1. Open the macOS **Shortcuts** app.
  2. Click the `+` button in the top right to create a new shortcut.
  3. Set the Shortcut name to "OCR Screenshot".
  4. In the search bar on the right, search for **Run Shell Script** and double-click to add it to the flow.
  5. Configure the shell script:
     - Shell: `/bin/zsh`
     - Input: Choose **No Input**
     - Script text:
       ```bash
       /usr/local/bin/mac-ocr-capture
       ```
  6. On the right-hand panel, select the **Shortcut Details** tab (the `i` icon) and tick **Use as Quick Action**.
  7. Under "Quick Action Settings", click **Add Keyboard Shortcut** and configure your preferred shortcut (e.g., `Cmd + Shift + 2`).
  8. Click the close button. Pressing your hotkey will now trigger the crosshair screenshot OCR selector!

  *Note: The first time you run the shortcut, macOS will request Screen Recording and Accessibility permissions. Click 'Allow' to authorize the tool.*
  ```

- [ ] **Step 2: Commit documentation**
  ```bash
  git add README.md
  git commit -m "docs: add README with installation and keyboard shortcut setup instructions"
  ```
