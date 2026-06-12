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
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
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
                continuation.resume(returning: joinedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(url: url, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
