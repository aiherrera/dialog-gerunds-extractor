import Foundation

struct ProgressWire: Decodable, Sendable {
    var event: String
    var total: Int?
    var index: Int?
    var file: String?
    var code: String?
    var highlighted: Int?
    var excluded: Int?
    var highlightedTotal: Int?
    var excludedTotal: Int?
    var words: [String]?
    var message: String?
    var concordance: String?
    var failed: Bool?
    var corpus: String?
}

struct CorpusRunError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

enum ProjectPaths {
    static func root() -> URL? {
        let manager = FileManager.default
        var starts = [URL(fileURLWithPath: manager.currentDirectoryPath)]
        if let executable = Bundle.main.executableURL {
            starts.append(executable.deletingLastPathComponent())
        }
        starts.append(Bundle.main.bundleURL)

        for start in starts {
            var current = start
            for _ in 0..<8 {
                let index = current.appendingPathComponent("index.js")
                let exclusion = current.appendingPathComponent("utils/exclusion_list.txt")
                if manager.fileExists(atPath: index.path), manager.fileExists(atPath: exclusion.path) {
                    return current
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path { break }
                current = parent
            }
        }
        return nil
    }

    static func node() -> URL? {
        let manager = FileManager.default
        let nvm = manager.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node")
        let versions = (try? manager.contentsOfDirectory(at: nvm, includingPropertiesForKeys: nil)) ?? []
        let bins = versions
            .map { $0.appendingPathComponent("bin/node") }
            .filter { manager.isExecutableFile(atPath: $0.path) }
        if let best = bins.max(by: { isOlder($0, $1) }) {
            return best
        }
        for path in ["/opt/homebrew/bin/node", "/usr/local/bin/node", "/usr/bin/node"] {
            if manager.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    static func corpusDirectory() -> URL? {
        guard let root = root() else { return nil }
        let corpus = root.appendingPathComponent("corpus")
        if FileManager.default.fileExists(atPath: corpus.path) { return corpus }
        return root
    }

    private static func isOlder(_ lhs: URL, _ rhs: URL) -> Bool {
        let left = versionParts(lhs)
        let right = versionParts(rhs)
        let count = max(left.count, right.count)
        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a != b { return a < b }
        }
        return false
    }

    private static func versionParts(_ url: URL) -> [Int] {
        let name = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return name.split(separator: ".").compactMap { Int($0.filter(\.isNumber)) }
    }
}

enum CorpusRunner {
    static func run(
        project: URL,
        node: URL,
        arguments: [String],
        onEvent: @escaping @Sendable (ProgressWire) -> Void
    ) async throws -> String {
        let process = Process()
        process.executableURL = node
        process.arguments = arguments
        process.currentDirectoryURL = project

        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors

        try process.run()

        let decoder = JSONDecoder()
        let outputHandle = output.fileHandleForReading
        let errorHandle = errors.fileHandleForReading
        let stderr = StderrBox()
        DispatchQueue.global(qos: .utility).async {
            stderr.text = String(data: errorHandle.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            stderr.done = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var pending = Data()
                var concordance: String?
                var failure: String?

                while true {
                    let chunk = outputHandle.availableData
                    if chunk.isEmpty { break }
                    pending.append(chunk)
                    while let newline = pending.firstIndex(of: 10) {
                        let lineData = pending.prefix(upTo: newline)
                        pending.removeSubrange(pending.startIndex...newline)
                        guard let line = String(data: lineData, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines),
                            !line.isEmpty,
                            let data = line.data(using: .utf8),
                            let wire = try? decoder.decode(ProgressWire.self, from: data)
                        else { continue }

                        if wire.event == "done", let path = wire.concordance {
                            concordance = path
                        }
                        if wire.event == "error", let message = wire.message {
                            failure = message
                        }
                        let event = wire
                        DispatchQueue.main.async {
                            onEvent(event)
                        }
                    }
                }

                process.waitUntilExit()
                while !stderr.done {
                    Thread.sleep(forTimeInterval: 0.01)
                }
                let status = process.terminationStatus
                let finished = concordance
                let logged = stderr.text

                DispatchQueue.main.async {
                    if status == 0, let finished {
                        continuation.resume(returning: finished)
                    } else {
                        let message = failure?.isEmpty == false
                            ? failure!
                            : (logged.isEmpty ? "No pude procesar el corpus." : logged)
                        continuation.resume(throwing: CorpusRunError(message: message))
                    }
                }
            }
        }
    }
}

private final class StderrBox: @unchecked Sendable {
    var text = ""
    var done = false
}
