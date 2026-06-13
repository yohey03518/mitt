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
