import Foundation

enum EnvironmentError: LocalizedError {
    case missingAPIKey([String])

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let searchedPaths):
            let locations = searchedPaths.isEmpty ? "No .env paths were available." : searchedPaths.joined(separator: "\n")
            return "OPENAI_API_KEY bulunamadı. Proje kökündeki .env dosyasına kendi anahtarını ekle.\n\nAranan konumlar:\n\(locations)"
        }
    }
}

struct AppEnvironment: Sendable {
    let apiKey: String
    let model: String
    let sourceDescription: String
}

enum EnvironmentLoader {
    static func load() throws -> AppEnvironment {
        let process = ProcessInfo.processInfo.environment
        if let apiKey = clean(process["OPENAI_API_KEY"]), !apiKey.isEmpty {
            return AppEnvironment(
                apiKey: apiKey,
                model: clean(process["OPENAI_MODEL"]) ?? "gpt-5.6-luna",
                sourceDescription: "process environment"
            )
        }

        let candidates = envCandidates()
        for url in candidates {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let values = parse(content)
            guard let apiKey = clean(values["OPENAI_API_KEY"]), !apiKey.isEmpty else { continue }
            return AppEnvironment(
                apiKey: apiKey,
                model: clean(values["OPENAI_MODEL"]) ?? "gpt-5.6-luna",
                sourceDescription: url.path
            )
        }

        throw EnvironmentError.missingAPIKey(candidates.map(\.path))
    }

    static func parse(_ content: String) -> [String: String] {
        var values: [String: String] = [:]
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#"), let separator = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value.removeFirst()
                value.removeLast()
            }
            values[key] = value
        }
        return values
    }

    private static func envCandidates() -> [URL] {
        var candidates: [URL] = []
        let fileManager = FileManager.default

        candidates.append(URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(".env"))

        let bundleParent = Bundle.main.bundleURL.deletingLastPathComponent()
        candidates.append(bundleParent.appendingPathComponent(".env"))
        candidates.append(bundleParent.deletingLastPathComponent().appendingPathComponent(".env"))

        if let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            candidates.append(support.appendingPathComponent("DailyAgent/.env"))
        }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0.standardizedFileURL.path).inserted }
    }

    private static func clean(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
