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

## Language Configuration

By default, the tool performs OCR using macOS's default detection (system preferred languages). To specify custom target languages, pass them in a comma-separated format using the `--lang` or `-l` flags:

```bash
# OCR using English and Simplified Chinese
# Always put the more complex languagge first
mac-ocr-capture --lang zh-Hans,en-US
```

Language codes should follow the BCP 47 standard. Supported languages in macOS Vision include:

| Language | Code |
| :--- | :--- |
| **Traditional Chinese** | `zh-Hant` |
| **Simplified Chinese** | `zh-Hans` |
| **Traditional Cantonese** | `yue-Hant` |
| **Simplified Cantonese** | `yue-Hans` |
| **English (US)** | `en-US` |
| **Japanese** | `ja-JP` |
| **Korean** | `ko-KR` |
| **Vietnamese** | `vi-VT` |
| **Spanish** | `es-ES` |
| **French** | `fr-FR` |
| **German** | `de-DE` |
| **Italian** | `it-IT` |
| **Portuguese (Brazil)** | `pt-BR` |
| **Russian** | `ru-RU` |
| **Ukrainian** | `uk-UA` |
| **Thai** | `th-TH` |
| **Arabic** | `ar-SA` or `ars-SA` |

*Note: Indonesian (`id-ID`) is not natively supported by macOS Vision's OCR framework. If passed, the system will fall back to using default/English detection.*

> [!TIP]
> **Language Ordering Matters:** The Vision framework processes the languages in the order they are provided. If you put `en-US` first (e.g., `--lang en-US,zh-Hant`), it may fail to recognize Chinese characters. Always put the more complex script first (e.g., `--lang zh-Hant,en-US`).
> Also, the Chinese model (`zh-Hant`) natively recognizes Latin/English characters by default, so specifying `--lang zh-Hant` alone is usually sufficient for mixed Chinese-English text.



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

## Alternative: How to Configure keyboard shortcut using Raycast (Highly Recommended)

Using a dedicated global launcher like **Raycast** is highly recommended over the macOS Shortcuts app. Because Raycast runs as a unified background process, you only need to grant screen recording permissions to Raycast once, completely avoiding per-app permission prompts.

1. Open Raycast and search for **Create Script Command**.
2. Configure the script form:
   - **Template**: `Bash`
   - **Mode**: `Silent` (Runs completely in the background without opening the Raycast window)
   - **Title**: `OCR Screenshot`
   - **Description**: `Capture screen region and run OCR`
3. Click **Create Script** (or press `Cmd + Enter`) and save it to a script folder (e.g., `~/RaycastScripts/ocr-screenshot.sh`).
4. Open the generated file in a text editor and append the command path at the bottom:
   ```bash
   /usr/local/bin/mac-ocr-capture
   ```
5. Save the file.
6. Open Raycast, search for `OCR Screenshot`, press `Cmd + Shift + ,` (or go to Extensions -> Custom Scripts) and configure a **Hotkey** (e.g., `Cmd + Shift + 2`).

## Troubleshooting & FAQ

### 1. I press the hotkey but nothing happens
- **Run in Terminal**: Open **Terminal** and execute `/usr/local/bin/mac-ocr-capture` directly to check for error outputs.
- **Permission Denied**: Ensure the binary has executable permissions by running:
  ```bash
  chmod +x /usr/local/bin/mac-ocr-capture
  ```
- **System Settings Check**: Make sure the keyboard shortcut is enabled in **System Settings** -> **Keyboard** -> **Keyboard Shortcuts...** -> **Services** -> **General** -> check **OCR Screenshot**.
- **Conflict**: If the shortcut is swallowed, another app (e.g., WeChat, LINE, Raycast, Discord) might have registered it globally. Try changing it to a unique combination (like `Cmd + Opt + Ctrl + O`) to test.

### 2. Permissions block execution in certain applications
If using the native **Shortcuts** app, macOS services execute under the active app's context. If you experience TCC permission blocks:
1. Go to **System Settings** -> **Privacy & Security** -> **Screen & System Audio Recording**.
2. Ensure **Shortcuts** and the active application (e.g., Google Chrome) are toggled **ON**.
3. Alternatively, migrate to the **Raycast** method above, which runs out-of-context and bypasses per-app prompts.

### 3. Shortcuts app forces a variable in the "Input" field
In the macOS Shortcuts app, if a shortcut is configured as a Quick Action, it automatically assigns a variable to the script input, displaying `Input: [Input]` and `Send Input: [to stdin]`.
- **Does it matter?**: No. You can ignore it and save. The tool completely ignores standard input.
- **How to clear it**: Right-click the blue `Input` variable pill in the Shortcuts app and click **Clear** or **Clear Variable**, or disable the input settings at the very top of the Shortcuts window.
