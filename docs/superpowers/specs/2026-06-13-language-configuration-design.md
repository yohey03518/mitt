# Design Document: Language Configuration for macOS OCR CLI

## Overview
This document specifies the design for adding customizable language support to the `mac-ocr-capture` command-line utility. The primary goal is to allow users to specify one or more target languages via command-line arguments, especially when running the utility via a Raycast Script Command.

## Requirements
* **Configurability:** Users should be able to pass a list of target languages (e.g. `en-US`, `zh-Hans`, `ja-JP`) to the command-line tool.
* **Compatibility:** Default behavior (when no language is passed) must remain unchanged, falling back to macOS's default detection (system preferred languages).
* **Zero Dependencies:** The implementation must not introduce external package dependencies.
* **Raycast Integration:** Raycast scripts should be able to specify the language options transparently via CLI arguments.

## Architecture & Code Changes

### 1. Parsing CLI Arguments in `main.swift`
We will add a parsing helper in `main.swift` to extract language arguments.
```swift
/// Parses the arguments looking for `--lang` or `-l` flags and returns an array of language codes.
func parseLanguages(from arguments: [String]) -> [String] {
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
```
In `main()`, we parse the language arguments and pass them to the OCR manager:
```swift
let languages = parseLanguages(from: CommandLine.arguments)
let recognizedText = try await ocrManager.recognizeText(fromImageAt: tempFileURL, languages: languages)
```

### 2. Updating OCR Engine in `OCRManager.swift`
We will update `OCRManagerProtocol` and `OCRManager` to accept the `languages` array:
```swift
protocol OCRManagerProtocol {
    func recognizeText(fromImageAt url: URL, languages: [String]) async throws -> String
}
```
Inside the `VNRecognizeTextRequest` block, we will set the `recognitionLanguages` property on the request:
```swift
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

if !languages.isEmpty {
    request.recognitionLanguages = languages
}
```

### 3. Raycast Integration
In the Raycast Script Command file (e.g. `~/RaycastScripts/ocr-screenshot.sh`), users can configure the command line invocation:
```bash
/usr/local/bin/mac-ocr-capture --lang en-US,zh-Hans,ja-JP
```

## Testing Plan
1. **No Arguments:** Verify the tool runs as before and defaults to the system language.
2. **Single Language:** Verify `mac-ocr-capture --lang zh-Hans` works and correctly detects Simplified Chinese text.
3. **Multiple Languages:** Verify `mac-ocr-capture --lang en-US,ja-JP` works and detects both scripts when present.
4. **Invalid Flag:** Verify passing unrecognized flags does not crash the utility.
