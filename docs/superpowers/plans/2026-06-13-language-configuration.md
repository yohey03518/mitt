# Language Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to specify target OCR languages via a `--lang` or `-l` CLI flag, supporting multiple comma-separated languages, which will be passed to macOS's native Vision framework in Raycast or direct execution.

**Architecture:** 
1. Create a `LanguageParser` helper to parse `--lang` and `-l` flags from command line arguments.
2. Update `OCRManager` to accept an array of language codes and set `VNRecognizeTextRequest.recognitionLanguages` when non-empty.
3. Integrate the parser in `main.swift` and update CLI usage.

**Tech Stack:** Swift, macOS Vision Framework, Swift Testing

---

### Task 1: Update OCRManager and OCRManagerProtocol

**Files:**
- Modify: `Sources/mac-ocr-capture/OCRManager.swift`
- Modify: `Tests/mac-ocr-captureTests/OCRManagerTests.swift`

- [ ] **Step 1: Write the failing tests (updates to compilation & signatures)**
  Open `Tests/mac-ocr-captureTests/OCRManagerTests.swift` and modify the existing call and add a new test for custom languages:
  ```swift
  // Replace line 67:
  // let text = try await manager.recognizeText(fromImageAt: tempURL)
  // With:
  let text = try await manager.recognizeText(fromImageAt: tempURL, languages: [])
  ```
  And add a new test inside the `OCRManagerTests` struct:
  ```swift
  @Test func testOCRWithSpecificLanguages() async throws {
      let textToRender = "HELLO LANGUAGE TEST"
      let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_ocr_lang_\(UUID().uuidString).png")
      
      // Draw image
      let size = CGSize(width: 400, height: 100)
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
          Issue.record("Failed to create CGContext")
          return
      }
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
      
      NSGraphicsContext.saveGraphicsState()
      let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
      NSGraphicsContext.current = nsContext
      attributedString.draw(in: CGRect(x: 0, y: 30, width: size.width, height: size.height - 30))
      NSGraphicsContext.restoreGraphicsState()
      
      guard let cgImage = context.makeImage(),
            let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
          Issue.record("Failed to make image/destination")
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

      let manager = OCRManager()
      // We pass specific languages to the new API signature
      let text = try await manager.recognizeText(fromImageAt: tempURL, languages: ["en-US"])
      #expect(text.contains("HELLO"))
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `swift test`
  Expected: Compilation failure because `recognizeText(fromImageAt:languages:)` is not defined.

- [ ] **Step 3: Update OCRManagerProtocol and OCRManager**
  Open `Sources/mac-ocr-capture/OCRManager.swift` and update the definition:
  ```swift
  protocol OCRManagerProtocol {
      func recognizeText(fromImageAt url: URL, languages: [String]) async throws -> String
  }
  
  struct OCRManager: OCRManagerProtocol {
      func recognizeText(fromImageAt url: URL, languages: [String]) async throws -> String {
          guard FileManager.default.fileExists(atPath: url.path) else {
              throw NSError(domain: "OCRManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found at \(url.path)"])
          }
          
          return try await Task.detached(priority: .userInitiated) {
              let request = VNRecognizeTextRequest()
              request.recognitionLevel = .accurate
              request.usesLanguageCorrection = true
              
              if !languages.isEmpty {
                  request.recognitionLanguages = languages
              }
              
              let handler = VNImageRequestHandler(url: url, options: [:])
              try handler.perform([request])
              
              guard let observations = request.results else {
                  return ""
              }
              
              // Group observations into rows to preserve strict weak ordering
              let sortedByY = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
              var rows: [[VNRecognizedTextObservation]] = []
              for obs in sortedByY {
                  if var lastRow = rows.last,
                     let representative = lastRow.first,
                     abs(representative.boundingBox.origin.y - obs.boundingBox.origin.y) < (representative.boundingBox.height * 0.6) {
                      lastRow.append(obs)
                      rows[rows.count - 1] = lastRow
                  } else {
                      rows.append([obs])
                  }
              }
              
              let sortedObservations = rows.flatMap { row in
                  row.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
              }
              
              let recognizedStrings = sortedObservations.compactMap { observation in
                  observation.topCandidates(1).first?.string
              }
              
              return recognizedStrings.joined(separator: "\n")
          }.value
      }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `swift test`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add Sources/mac-ocr-capture/OCRManager.swift Tests/mac-ocr-captureTests/OCRManagerTests.swift
  git commit -m "feat: support passing languages list to OCRManager"
  ```

---

### Task 2: Create LanguageParser and unit tests

**Files:**
- Create: `Sources/mac-ocr-capture/LanguageParser.swift`
- Create: `Tests/mac-ocr-captureTests/LanguageParserTests.swift`

- [ ] **Step 1: Write the failing tests**
  Create `Tests/mac-ocr-captureTests/LanguageParserTests.swift`:
  ```swift
  import Testing
  @testable import mac_ocr_capture
  
  @Suite struct LanguageParserTests {
      @Test func testParseLanguagesWithFlag() {
          let args = ["/path/to/binary", "--lang", "zh-Hans,ja-JP,en-US"]
          let result = LanguageParser.parseLanguages(from: args)
          #expect(result == ["zh-Hans", "ja-JP", "en-US"])
      }
      
      @Test func testParseLanguagesWithShortFlag() {
          let args = ["/path/to/binary", "-l", "en-US"]
          let result = LanguageParser.parseLanguages(from: args)
          #expect(result == ["en-US"])
      }
      
      @Test func testParseLanguagesNoFlag() {
          let args = ["/path/to/binary"]
          let result = LanguageParser.parseLanguages(from: args)
          #expect(result.isEmpty)
      }
      
      @Test func testParseLanguagesEmptyValue() {
          let args = ["/path/to/binary", "--lang", ""]
          let result = LanguageParser.parseLanguages(from: args)
          #expect(result.isEmpty)
      }
      
      @Test func testParseLanguagesMissingValue() {
          let args = ["/path/to/binary", "--lang"]
          let result = LanguageParser.parseLanguages(from: args)
          #expect(result.isEmpty)
      }
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `swift test`
  Expected: Compilation failure because `LanguageParser` does not exist.

- [ ] **Step 3: Write minimal implementation**
  Create `Sources/mac-ocr-capture/LanguageParser.swift`:
  ```swift
  import Foundation
  
  struct LanguageParser {
      static func parseLanguages(from arguments: [String]) -> [String] {
          guard let flagIndex = arguments.firstIndex(where: { $0 == "--lang" || $0 == "-l" }),
                flagIndex + 1 < arguments.count else {
              return []
          }
          let langString = arguments[flagIndex + 1]
          return langString
              .split(separator: ",")
              .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
              .filter { !$0.isEmpty }
      }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `swift test`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add Sources/mac-ocr-capture/LanguageParser.swift Tests/mac-ocr-captureTests/LanguageParserTests.swift
  git commit -m "feat: add LanguageParser helper with unit tests"
  ```

---

### Task 3: Integrate LanguageParser in main.swift

**Files:**
- Modify: `Sources/mac-ocr-capture/main.swift`

- [ ] **Step 1: Update main.swift entry point**
  Open `Sources/mac-ocr-capture/main.swift`.
  Change:
  ```swift
  // Line 30:
  // let recognizedText = try await ocrManager.recognizeText(fromImageAt: tempFileURL)
  ```
  To:
  ```swift
  let languages = LanguageParser.parseLanguages(from: CommandLine.arguments)
  let recognizedText = try await ocrManager.recognizeText(fromImageAt: tempFileURL, languages: languages)
  ```

- [ ] **Step 2: Run all tests to make sure they pass**
  Run: `swift test`
  Expected: PASS

- [ ] **Step 3: Build tool and manually verify execution**
  Build: `swift build -c release`
  Run without languages (should trigger screenshot cursor): `.build/release/mac-ocr-capture`
  Run with languages: `.build/release/mac-ocr-capture --lang en-US`

- [ ] **Step 4: Commit**
  ```bash
  git add Sources/mac-ocr-capture/main.swift
  git commit -m "feat: integrate LanguageParser into main entry point"
  ```
