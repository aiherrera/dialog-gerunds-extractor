import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class CorpusStore {
    var hits: [Hit] = []
    var loadError: String?
    var processError: String?
    var isProcessing = false
    var progress = ProcessProgress()
    var corpusLabel = ""
    var section: AppSection = .overview
    var query = ""
    var speaker: SpeakerFilter = .all
    var ending: EndingFilter = .all
    var pronoun: PronounFilter = .all
    var group = "Todas"
    var selection: String?
    var showImporter = false
    var showAbout = false
    var exclusions: [String] = []
    var exclusionDraft = ""
    var exclusionQuery = ""
    var exclusionNote: String?
    private var corpusURL: URL?
    var queryKind = "gerundios"
    var queryReading = ""
    var queryRequest = ""
    private var concordanceURL: URL?
    private var summary = ResultSnapshot()
    private var refreshTask: Task<Void, Never>?
    private var interviews: [String: [String]]?
    var hitsReady = false
    var revision = 0
    var snapshot = ResultSnapshot()
    var visible: [Hit] = []
    var selectedHit: Hit?
    var selectedTurn = ""

    var showsGerundDetail: Bool {
        queryKind.isEmpty || queryKind == "gerundios"
    }

    var resultNoun: String {
        switch queryKind {
        case "perifrasis": return "perífrasis"
        case "predicativo": return "gerundios\npredicativos"
        case "sustantivos": return "sustantivos"
        case "verbos": return "verbos"
        case "forma", "terminacion", "estructura":
            let text = queryRequest.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { return "resultados" }
            if text.count <= 42 { return text }
            return String(text.prefix(41)) + "…"
        default: return "gerundios\nencontrados"
        }
    }

    init() {
        loadExclusions()
        if let corpus = Self.rememberedCorpus() ?? Self.projectCorpus() {
            corpusURL = corpus
            corpusLabel = corpus.lastPathComponent
        }
        if let url = Self.findDefault() {
            load(url)
        } else {
            loadError = "Elige la carpeta del corpus para empezar."
        }
    }

    var groupNames: [String] { snapshot.groupNames }

    private var filtersAreActive: Bool {
        if speaker != .all || ending != .all || pronoun != .all || group != "Todas" { return true }
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
            refresh()
        }
    }

    func refresh() {
        guard hitsReady else {
            snapshot = summary
            visible = []
            revision += 1
            return
        }
        if !filtersAreActive {
            snapshot = summary
            visible = hits
        } else {
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).folded
            visible = hits.filter { hit in
                if speaker != .all, hit.speaker != speaker.rawValue { return false }
                if ending != .all, hit.ending != ending.rawValue { return false }
                if pronoun == .with, hit.clitic.isEmpty { return false }
                if pronoun == .without, !hit.clitic.isEmpty { return false }
                if group != "Todas", hit.group != group { return false }
                if !needle.isEmpty, !hit.searchKey.contains(needle) { return false }
                return true
            }
            snapshot = Self.snapshot(from: visible, groupNames: summary.groupNames)
        }
        revision += 1
        if let selection, !visible.contains(where: { $0.id == selection }) {
            self.selection = nil
            selectedHit = nil
            selectedTurn = ""
        }
    }

    func select(_ id: String) {
        selection = id
        selectedHit = hits.first { $0.id == id }
        selectedTurn = selectedHit?.turn ?? ""
        guard selectedTurn.isEmpty, let hit = selectedHit, hit.paragraph != nil else { return }
        Task { await resolveTurn(for: hit) }
    }

    func load(_ url: URL) {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values?.fileSize, size > 12_000_000 {
            loadError = "La concordancia guardada es demasiado grande. Busca otra vez para regenerarla."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(ConcordanceFile.self, from: data)
            loadError = nil
            concordanceURL = url
            queryKind = file.kind ?? "gerundios"
            queryReading = file.reading ?? ""
            queryRequest = file.request ?? ""
            summary = Self.snapshot(from: file)
            snapshot = summary
            hits = []
            visible = []
            hitsReady = false
            selection = nil
            selectedHit = nil
            selectedTurn = ""
            revision += 1

            if let embedded = file.hits, !embedded.isEmpty {
                install(embedded)
                return
            }

            let hitsURL = url.deletingLastPathComponent().appendingPathComponent("concordance-hits.json")
            guard FileManager.default.fileExists(atPath: hitsURL.path) else {
                hitsReady = true
                return
            }
            Task.detached(priority: .userInitiated) {
                do {
                    let loaded = try Data(contentsOf: hitsURL)
                    let decoded = try JSONDecoder().decode([Hit].self, from: loaded)
                    await self.install(decoded)
                } catch {
                    await self.failLoad("No pude leer los ejemplos.")
                }
            }
        } catch {
            loadError = "No pude leer la concordancia. \(error.localizedDescription)"
        }
    }

    private func install(_ loaded: [Hit]) {
        hits = loaded
        hitsReady = true
        refresh()
        if selection == nil, let first = loaded.first {
            select(first.id)
        }
    }

    private func resolveTurn(for hit: Hit) async {
        guard let index = hit.paragraph else { return }
        if interviews == nil {
            guard let root = ProjectPaths.root() else { return }
            let url = root.appendingPathComponent("output/cache/interviews.json")
            let loaded: [String: [String]]? = await Task.detached(priority: .utility) {
                guard let data = try? Data(contentsOf: url),
                      let file = try? JSONDecoder().decode(InterviewCache.self, from: data) else { return nil }
                var map: [String: [String]] = [:]
                map.reserveCapacity(file.files.count)
                for item in file.files {
                    map[item.code] = item.paragraphs.map(\.text)
                }
                return map
            }.value
            interviews = loaded ?? [:]
        }
        guard selection == hit.id, let text = interviews?[hit.code]?[index] else { return }
        selectedTurn = text
    }

    private func failLoad(_ message: String) {
        loadError = message
        hitsReady = true
    }

    private static func snapshot(from file: ConcordanceFile) -> ResultSnapshot {
        if file.speakers == nil, let hits = file.hits {
            return snapshot(from: hits, groupNames: [])
        }
        var result = ResultSnapshot()
        result.total = file.count
        result.speakers = speakerRows(file.speakers ?? [:])
        result.sexes = sexRows(file.sexes ?? [:])
        result.endings = endingRows(file.endings ?? [:])
        let withPronoun = file.withPronoun ?? 0
        result.pronouns = counted([
            ("Sin pronombre", max(file.count - withPronoun, 0)),
            ("Con pronombre", withPronoun),
        ])
        result.groups = (file.groups ?? [:])
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
        result.groupNames = result.groups.map(\.0)
        result.types = (file.types ?? []).map {
            TypeCount(word: $0.word, count: $0.count, ending: $0.ending)
        }
        result.forms = formRows(result.types, total: file.count)
        return result
    }

    private static func snapshot(from hits: [Hit], groupNames: [String]) -> ResultSnapshot {
        var speakers: [String: Int] = [:]
        var sexes: [String: Int] = [:]
        var endings: [String: Int] = [:]
        var groups: [String: Int] = [:]
        var withPronoun = 0
        var types: [String: (count: Int, ending: String)] = [:]
        types.reserveCapacity(hits.count / 8)

        for hit in hits {
            speakers[hit.speaker, default: 0] += 1
            if !hit.sex.isEmpty { sexes[hit.sex, default: 0] += 1 }
            if !hit.ending.isEmpty { endings[hit.ending, default: 0] += 1 }
            if !hit.group.isEmpty { groups[hit.group, default: 0] += 1 }
            if !hit.clitic.isEmpty { withPronoun += 1 }
            if let current = types[hit.word] {
                types[hit.word] = (current.count + 1, current.ending)
            } else {
                types[hit.word] = (1, hit.ending)
            }
        }

        var result = ResultSnapshot()
        result.total = hits.count
        result.speakers = speakerRows(speakers)
        result.sexes = sexRows(sexes)
        result.endings = endingRows(endings)
        result.pronouns = counted([
            ("Sin pronombre", hits.count - withPronoun),
            ("Con pronombre", withPronoun),
        ])
        result.groups = groups.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
        result.groupNames = groupNames.isEmpty ? result.groups.map(\.0) : groupNames
        result.types = types
            .map { TypeCount(word: $0.key, count: $0.value.count, ending: $0.value.ending) }
            .sorted { left, right in
                if left.count != right.count { return left.count > right.count }
                return left.word < right.word
            }
        result.forms = formRows(result.types, total: hits.count)
        return result
    }

    private static func speakerRows(_ counts: [String: Int]) -> [(String, Int)] {
        let other = (counts["O"] ?? 0) + (counts["V"] ?? 0)
        return counted([
            ("Informante", counts["I"] ?? 0),
            ("Entrevistador", counts["E"] ?? 0),
            ("Sin etiqueta", counts["untagged"] ?? 0),
            ("Otro", other),
        ])
    }

    private static func sexRows(_ counts: [String: Int]) -> [(String, Int)] {
        counted([
            ("Mujeres", counts["M"] ?? 0),
            ("Hombres", counts["H"] ?? 0),
        ])
    }

    private static func endingRows(_ counts: [String: Int]) -> [(String, Int)] {
        counted([
            ("-ando", counts["ando"] ?? 0),
            ("-iendo", counts["iendo"] ?? 0),
            ("-yendo", counts["yendo"] ?? 0),
        ])
    }

    private static func formRows(_ types: [TypeCount], total: Int) -> [(String, Int)] {
        let top = types.prefix(4)
        let shown = top.reduce(0) { $0 + $1.count }
        var rows = top.map { (clipped($0.word), $0.count) }
        let rest = total - shown
        if rest > 0 { rows.append(("Otras", rest)) }
        return rows.filter { $0.1 > 0 }
    }

    private static func clipped(_ word: String) -> String {
        if word.count <= 28 { return word }
        return String(word.prefix(27)) + "…"
    }

    private static func counted(_ rows: [(String, Int)]) -> [(String, Int)] {
        rows.filter { $0.1 > 0 }
    }

    var caption: String {
        var parts: [String] = []
        if speaker != .all { parts.append(speaker.title) }
        if ending != .all { parts.append(ending.title) }
        if pronoun != .all { parts.append(pronoun.title) }
        if group != "Todas" { parts.append(group) }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { parts.append("«\(trimmed)»") }
        return parts.isEmpty ? "Todas las entrevistas" : parts.joined(separator: " · ")
    }

    func pickCorpus() {
        guard !isProcessing else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Procesar"
        panel.message = "Elige la carpeta con las entrevistas del corpus."
        panel.directoryURL = ProjectPaths.corpusDirectory()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        rememberCorpus(url)
        Task { await process(corpus: url) }
    }

    var canReprocess: Bool {
        guard !isProcessing, let corpusURL else { return false }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: corpusURL.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func reprocess() {
        guard let corpusURL, canReprocess else { return }
        Task { await process(corpus: corpusURL) }
    }

    func clearCorpus() {
        guard !isProcessing, !hits.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = "Limpiar el corpus"
        alert.informativeText = "Se quitan de Andante la concordancia, las estadísticas y los documentos resaltados. Las entrevistas originales no se tocan."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Limpiar")
        alert.addButton(withTitle: "Cancelar")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        do {
            try removeGeneratedOutput()
        } catch {
            processError = "No pude limpiar los archivos generados. \(error.localizedDescription)"
            return
        }

        hits = []
        visible = []
        hitsReady = false
        summary = ResultSnapshot()
        snapshot = ResultSnapshot()
        selectedHit = nil
        selectedTurn = ""
        interviews = nil
        concordanceURL = nil
        loadError = nil
        processError = nil
        progress = ProcessProgress()
        corpusLabel = ""
        queryKind = "gerundios"
        queryReading = ""
        queryRequest = ""
        query = ""
        speaker = .all
        ending = .all
        pronoun = .all
        group = "Todas"
        selection = nil
        section = .overview
    }

    private func removeGeneratedOutput() throws {
        guard let concordanceURL, let root = ProjectPaths.root() else { return }
        let output = root.appendingPathComponent("output").standardizedFileURL
        let file = concordanceURL.standardizedFileURL
        let inside = file.path == output.path || file.path.hasPrefix(output.path + "/")
        guard inside, FileManager.default.fileExists(atPath: output.path) else { return }
        try FileManager.default.removeItem(at: output)
    }

    func process(corpus: URL) async {
        guard !isProcessing else { return }
        guard let project = ProjectPaths.root() else {
            processError = "No encuentro el proyecto junto a la app."
            return
        }
        guard let node = ProjectPaths.node() else {
            processError = "No encuentro Node.js en esta Mac."
            return
        }

        isProcessing = true
        processError = nil
        queryKind = "gerundios"
        queryReading = "Gerundios en -ando, -iendo o -yendo, con o sin pronombre."
        queryRequest = "gerundios"
        rememberCorpus(corpus)
        let folder = corpus.lastPathComponent
        progress = ProcessProgress(corpusName: folder)
        corpusLabel = folder

        let accessing = corpus.startAccessingSecurityScopedResource()
        defer {
            if accessing { corpus.stopAccessingSecurityScopedResource() }
        }

        do {
            let concordance = try await CorpusRunner.run(
                project: project,
                node: node,
                arguments: [
                    project.appendingPathComponent("index.js").path,
                    "--corpus", corpus.path,
                    "--output", project.appendingPathComponent("output").path,
                    "--progress",
                ]
            ) { wire in
                Task { @MainActor in
                    self.apply(wire)
                }
            }
            load(URL(fileURLWithPath: concordance))
            query = ""
            speaker = .all
            ending = .all
            pronoun = .all
            group = "Todas"
            section = .overview
            isProcessing = false
        } catch {
            processError = error.localizedDescription
            isProcessing = false
        }
    }

    private func apply(_ wire: ProgressWire) {
        switch wire.event {
        case "start":
            progress.total = wire.total ?? 0
        case "begin":
            progress.currentFile = wire.file ?? ""
            progress.currentCode = wire.code ?? ""
            progress.words = []
        case "file":
            progress.completed = wire.index ?? progress.completed
            progress.currentFile = wire.file ?? progress.currentFile
            progress.currentCode = wire.code ?? progress.currentCode
            progress.highlighted = wire.highlightedTotal ?? progress.highlighted
            progress.excluded = wire.excludedTotal ?? progress.excluded
            progress.words = wire.words ?? []
            progress.files.insert(
                ProcessedFile(
                    id: wire.index ?? progress.files.count,
                    code: wire.code ?? wire.file ?? "—",
                    highlighted: wire.highlighted ?? 0,
                    failed: wire.failed ?? false,
                    note: wire.message ?? ""
                ),
                at: 0
            )
        case "error":
            processError = wire.message
        default:
            break
        }
    }

    static func findDefault() -> URL? {
        var starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath)]
        if let executable = Bundle.main.executableURL {
            starts.append(executable.deletingLastPathComponent())
        }
        starts.append(Bundle.main.bundleURL)

        for start in starts {
            var current = start
            for _ in 0..<8 {
                let candidate = current.appendingPathComponent("output/concordance.json")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path { break }
                current = parent
            }
        }
        return nil
    }

    var visibleExclusions: [String] {
        let needle = exclusionQuery.trimmingCharacters(in: .whitespacesAndNewlines).folded
        guard !needle.isEmpty else { return exclusions }
        return exclusions.filter { $0.folded.contains(needle) }
    }

    func loadExclusions() {
        guard let url = Self.exclusionFile() else {
            exclusionNote = "No encuentro utils/exclusion_list.txt junto al proyecto."
            return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            exclusions = []
            return
        }
        do {
            let tokens = Self.exclusionTokens(in: try String(contentsOf: url, encoding: .utf8))
            var seen = Set<String>()
            exclusions = tokens.filter { seen.insert($0).inserted }
        } catch {
            exclusionNote = "No pude leer la lista de excepciones."
        }
    }

    func addDraftExclusion() {
        guard !isProcessing else { return }
        let tokens = Self.exclusionTokens(in: exclusionDraft)
        guard !tokens.isEmpty else { return }
        exclusionDraft = ""
        commitExclusions(tokens)
    }

    func importExclusions() {
        guard !isProcessing else { return }
        section = .exceptions
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Importar"
        panel.message = "Una forma por línea, o varias separadas por comas."
        panel.allowedContentTypes = [.plainText, .utf8PlainText, .commaSeparatedText]
        panel.allowsOtherFileTypes = true
        if let root = ProjectPaths.root() {
            panel.directoryURL = root.appendingPathComponent("utils")
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        guard let text = Self.readText(at: url) else {
            exclusionNote = "No pude leer ese archivo. Usa texto UTF-8."
            return
        }
        let tokens = Self.exclusionTokens(in: text)
        if tokens.isEmpty {
            exclusionNote = "Ese archivo no tiene formas para añadir."
            return
        }
        commitExclusions(tokens)
    }

    func removeExclusion(_ word: String) {
        guard !isProcessing else { return }
        let next = exclusions.filter { $0 != word }
        guard next.count != exclusions.count else { return }
        exclusions = next
        do {
            try saveExclusions()
            exclusionNote = "Se quitó «\(word)»."
        } catch {
            loadExclusions()
            exclusionNote = "No pude guardar la lista. \(error.localizedDescription)"
        }
    }

    private func commitExclusions(_ tokens: [String]) {
        var seen = Set(exclusions)
        var added = 0
        var skipped = 0
        var next = exclusions
        for token in tokens {
            if seen.contains(token) {
                skipped += 1
                continue
            }
            seen.insert(token)
            next.append(token)
            added += 1
        }
        guard added > 0 else {
            exclusionNote = skipped == 1 ? "Esa forma ya está en la lista." : "Esas formas ya están en la lista."
            return
        }
        let previous = exclusions
        exclusions = next
        do {
            try saveExclusions()
            exclusionNote = Self.exclusionNote(added: added, skipped: skipped)
        } catch {
            exclusions = previous
            exclusionNote = "No pude guardar la lista. \(error.localizedDescription)"
        }
    }

    private func saveExclusions() throws {
        guard let url = Self.exclusionFile() else {
            throw CorpusRunError(message: "No encuentro la carpeta del proyecto.")
        }
        let text = exclusions.joined(separator: "\n") + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func exclusionFile() -> URL? {
        ProjectPaths.root()?.appendingPathComponent("utils/exclusion_list.txt")
    }

    private static let corpusPathKey = "andante.corpusPath"

    private func rememberCorpus(_ url: URL) {
        corpusURL = url
        UserDefaults.standard.set(url.path, forKey: Self.corpusPathKey)
    }

    private static func rememberedCorpus() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: corpusPathKey) else { return nil }
        guard isCorpusDirectory(path) else { return nil }
        return URL(fileURLWithPath: path)
    }

    private static func projectCorpus() -> URL? {
        guard let corpus = ProjectPaths.corpusDirectory(), corpus.lastPathComponent == "corpus" else { return nil }
        guard isCorpusDirectory(corpus.path) else { return nil }
        return corpus
    }

    private static func isCorpusDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private static func readText(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let text = String(data: data, encoding: .utf8) { return text }
        return String(data: data, encoding: .isoLatin1)
    }

    static func exclusionTokens(in text: String) -> [String] {
        let locale = Locale(identifier: "es")
        var tokens: [String] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let pieces = line
                .components(separatedBy: CharacterSet(charactersIn: ",;\t"))
                .flatMap { $0.split(whereSeparator: \.isWhitespace).map(String.init) }
            for piece in pieces {
                let token = piece
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased(with: locale)
                guard isExceptionToken(token) else { continue }
                tokens.append(token)
            }
        }
        return tokens
    }

    private static func isExceptionToken(_ token: String) -> Bool {
        guard !token.isEmpty, token.count <= 64 else { return false }
        return token.allSatisfy { $0.isLetter || $0 == "_" || $0 == "-" }
    }

    private static func exclusionNote(added: Int, skipped: Int) -> String {
        let addedText = added == 1 ? "Se añadió 1 forma." : "Se añadieron \(added) formas."
        guard skipped > 0 else { return addedText }
        let skippedText = skipped == 1 ? "1 ya estaba." : "\(skipped) ya estaban."
        return "\(addedText) \(skippedText)"
    }
}

private struct InterviewCache: Decodable {
    struct File: Decodable {
        var code: String
        var paragraphs: [Paragraph]
    }

    struct Paragraph: Decodable {
        var text: String
    }

    var files: [File]
}
