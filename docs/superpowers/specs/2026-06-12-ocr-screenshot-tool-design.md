# Design Spec: Native macOS OCR Screenshot Tool

## Overview
This document specifies the design for a native macOS CLI utility that allows users to select a region of their screen, perform Optical Character Recognition (OCR) on that region using Apple's Vision framework, and automatically copy the extracted text to the system clipboard.

## Goals
- Provide a fast, lightweight, and native screenshot OCR experience on macOS.
- Zero third-party dependencies (no Python virtual environments, no Tesseract installations).
- Seamless clipboard integration.
- Clear visual feedback via native macOS system notifications.
- Easy integration with keyboard shortcuts (using native macOS Shortcuts, Automator, Raycast, Alfred, Karabiner, etc.).

## Non-Goals
- Building a complex GUI application or a background menu bar manager.
- Supporting non-macOS operating systems.
- Storing a history of captured screenshots (except for a temporary file during processing).

## Architecture & Components

### Component Breakdown
1. **Interactive Screen Capture**: 
   Spawns `/usr/sbin/screencapture` in interactive mode (`-i`) and rect-only mode (`-r`). It saves the selection to a temporary file path `/tmp/ocr_screenshot_temp.png`.
2. **OCR Engine**:
   Uses Apple's native **Vision Framework** (`VNRecognizeTextRequest` and `VNImageRequestHandler`). It uses the default primary languages supported by the operating system for recognition.
3. **Clipboard/Pasteboard Manager**:
   Uses the macOS `AppKit` library (`NSPasteboard.general`) to set the clipboard contents to the recognized text.
4. **Desktop Notification Wrapper**:
   Uses a shell execution of `osascript` to post a native macOS user notification with a preview of the copied text.
5. **File Cleanup**:
   Deletes the temporary file `/tmp/ocr_screenshot_temp.png` once OCR is complete or when an error/cancellation occurs.

### Workflow & Data Flow
1. **Invocation**: The tool is run (e.g., `mac-ocr-capture`).
2. **Capture**: 
   - Runs `/usr/sbin/screencapture -i -r /tmp/ocr_screenshot_temp.png` as a subprocess.
   - Waits for the process to exit.
   - If the exit code is non-zero (indicating the user pressed `Esc` to cancel), the tool exits cleanly.
3. **Processing**:
   - Reads the image file from disk.
   - Configures `VNRecognizeTextRequest` with:
     - `recognitionLevel = .accurate`
     - `usesLanguageCorrection = true`
   - Executes the request.
4. **Clipboard Integration**:
   - Collects all text blocks returned by Vision, ordering them top-to-bottom and left-to-right.
   - Joins them with newlines.
   - Writes the joined string to `NSPasteboard.general`.
5. **Notification**:
   - Triggers `osascript` to show a notification:
     * Title: `OCR Screenshot`
     * Message: `Text copied: "[First 50 characters of text]..."` (or a message stating no text was found).
6. **Cleanup**:
   - Deletes `/tmp/ocr_screenshot_temp.png`.
   - Exits process.

## Security & Permissions
- **Screen Recording Permission**: The application that triggers the CLI (e.g., Terminal, Shortcuts app, Alfred, Raycast) must have "Screen Recording" permissions granted under macOS *System Settings -> Privacy & Security -> Screen & System Audio Recording*. When first run, macOS will prompt the user to grant this.
- **Sandboxing**: The compiled CLI runs outside a sandbox, giving it access to `/tmp` and `NSPasteboard` without requiring app signing or provision profiling.

## Alternative Designs Considered
- **Swift Script (`#!/usr/bin/env swift`)**: Rejected due to a noticeable ~0.5s compile/startup delay on every run.
- **Python with PyObjC**: Rejected because it requires Python installation, virtual environments, and PyObjC packages, which are slow to install and run.
