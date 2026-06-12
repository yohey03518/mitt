import Foundation
import Vision

protocol OCRManagerProtocol {
    func recognizeText(fromImageAt url: URL) async throws -> String
}

struct OCRManager: OCRManagerProtocol {
    func recognizeText(fromImageAt url: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "OCRManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found at \(url.path)"])
        }
        
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
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
