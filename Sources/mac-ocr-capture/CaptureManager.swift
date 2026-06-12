import Foundation

protocol CaptureManagerProtocol {
    func captureInteractive(outputPath: String) throws -> Int32
}

struct CaptureManager: CaptureManagerProtocol {
    private let runProcess: (URL, [String]) throws -> Int32
    
    init(runProcess: @escaping (URL, [String]) throws -> Int32 = { url, args in
        let process = Process()
        process.executableURL = url
        process.arguments = args
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }) {
        self.runProcess = runProcess
    }
    
    func captureInteractive(outputPath: String) throws -> Int32 {
        let executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        let arguments = ["-i", "-r", outputPath]
        return try runProcess(executableURL, arguments)
    }
}
