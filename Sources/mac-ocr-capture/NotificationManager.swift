import Foundation

protocol NotificationManagerProtocol {
    func sendNotification(title: String, message: String) -> Bool
}

struct NotificationManager: NotificationManagerProtocol {
    private let runProcess: (URL, [String]) throws -> (Int32, Data)

    init(runProcess: @escaping (URL, [String]) throws -> (Int32, Data) = { url, args in
        let process = Process()
        process.executableURL = url
        process.arguments = args
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, errorData)
    }) {
        self.runProcess = runProcess
    }

    private func escapeForAppleScript(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    func makeScript(title: String, message: String) -> String {
        let escapedTitle = escapeForAppleScript(title)
        let escapedMessage = escapeForAppleScript(message)
        return "display notification \"\(escapedMessage)\" with title \"\(escapedTitle)\""
    }

    func sendNotification(title: String, message: String) -> Bool {
        let script = makeScript(title: title, message: message)
        let executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        
        do {
            let (terminationStatus, errorData) = try runProcess(executableURL, ["-e", script])
            
            let success = terminationStatus == 0
            if !success {
                if let errorMessage = String(data: errorData, encoding: .utf8), !errorMessage.isEmpty {
                    print("osascript error: \(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
            return success
        } catch {
            print("Failed to display notification: \(error)")
            return false
        }
    }
}
