# Native macOS OCR Screenshot Tool

A lightweight, zero-dependency command line utility that captures a region of the screen, OCRs the captured area via macOS's native Vision framework, copies it to the clipboard, and triggers a desktop notification.

## Requirements
- macOS 13.0 Ventura or later
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
