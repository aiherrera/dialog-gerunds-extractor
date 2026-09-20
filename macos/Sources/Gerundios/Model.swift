import SwiftUI

enum Brand {
    static let name = "Andante"
    static let authors = "Alain Iglesias  ·  Ailyn Figueroa"
    static let subtitle = "Gerundios del corpus"

    static var version: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        guard let value, !value.isEmpty else { return "1.0" }
        return value
    }

    static var build: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        guard let value, !value.isEmpty else { return "1" }
        return value
    }
}

struct ProcessedFile: Identifiable {
    var id: Int
    var code: String
    var highlighted: Int
    var failed: Bool
    var note: String
}

struct ProcessProgress {
    var total = 0
    var completed = 0
    var currentFile = ""
    var currentCode = ""
    var highlighted = 0
    var excluded = 0
    var words: [String] = []
    var files: [ProcessedFile] = []
    var corpusName = ""
}

enum Theme {
    static let paper = Color(red: 0.973, green: 0.957, blue: 0.933)
    static let paperDeep = Color(red: 0.945, green: 0.922, blue: 0.888)
    static let sidebar = Color(red: 0.918, green: 0.894, blue: 0.858)
    static let ink = Color(red: 0.145, green: 0.118, blue: 0.102)
    static let muted = Color(red: 0.42, green: 0.35, blue: 0.30)
    static let gerund = Color(red: 0.55, green: 0.15, blue: 0.12)
    static let selection = Color(red: 0.86, green: 0.76, blue: 0.66)
    static let rule = Color.black.opacity(0.08)
    static let bar = Color(red: 0.55, green: 0.15, blue: 0.12).opacity(0.78)
    static let series = [
        Color(red: 0.55, green: 0.15, blue: 0.12),
        Color(red: 0.29, green: 0.21, blue: 0.17),
        Color(red: 0.62, green: 0.45, blue: 0.32),
        Color(red: 0.73, green: 0.62, blue: 0.48),
    ]
}

enum AppSection: String, CaseIterable, Identifiable {
    case overview
    case concordance
    case frequency
    case exceptions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Resumen"
        case .concordance: "Concordancia"
        case .frequency: "Frecuencias"
        case .exceptions: "Excepciones"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "text.alignleft"
        case .concordance: "text.quote"
        case .frequency: "list.number"
        case .exceptions: "minus.circle"
        }
    }
}

enum SpeakerFilter: String, CaseIterable, Identifiable {
    case all
    case informant = "I"
    case interviewer = "E"
    case other = "O"
    case untagged = "untagged"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todos"
        case .informant: "Informante"
        case .interviewer: "Entrevistador"
        case .other: "Otro"
        case .untagged: "Sin etiqueta"
        }
    }
}

enum EndingFilter: String, CaseIterable, Identifiable {
    case all
    case ando
    case iendo
    case yendo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todas"
        case .ando: "-ando"
        case .iendo: "-iendo"
        case .yendo: "-yendo"
        }
    }
}

enum PronounFilter: String, CaseIterable, Identifiable {
    case all
    case with
    case without

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Todos"
        case .with: "Con pronombre"
        case .without: "Sin pronombre"
        }
    }
}

struct ConcordanceFile: Decodable {
    var count: Int
    var hits: [Hit]?
    var request: String?
    var reading: String?
    var kind: String?
    var speakers: [String: Int]?
    var sexes: [String: Int]?
    var groups: [String: Int]?
    var endings: [String: Int]?
    var withPronoun: Int?
    var types: [TypeWire]?
}

struct TypeWire: Decodable {
    var word: String
    var count: Int
    var ending: String
}

struct Hit: Decodable, Identifiable {
    var id: String
    var code: String
    var sex: String
    var group: String
    var speaker: String
    var word: String
    var ending: String
    var clitic: String
    var crossesTag: Bool
    var before: String
    var match: String
    var after: String
    var paragraph: Int?
    var turn: String
    var searchKey: String

    enum CodingKeys: String, CodingKey {
        case id, code, sex, group, speaker, word, ending, clitic, crossesTag
        case before, match, after, paragraph, turn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        sex = try container.decodeIfPresent(String.self, forKey: .sex) ?? ""
        group = try container.decodeIfPresent(String.self, forKey: .group) ?? ""
        speaker = try container.decodeIfPresent(String.self, forKey: .speaker) ?? ""
        word = try container.decodeIfPresent(String.self, forKey: .word) ?? ""
        ending = try container.decodeIfPresent(String.self, forKey: .ending) ?? ""
        clitic = try container.decodeIfPresent(String.self, forKey: .clitic) ?? ""
        crossesTag = try container.decodeIfPresent(Bool.self, forKey: .crossesTag) ?? false
        before = try container.decodeIfPresent(String.self, forKey: .before) ?? ""
        match = try container.decodeIfPresent(String.self, forKey: .match) ?? word
        after = try container.decodeIfPresent(String.self, forKey: .after) ?? ""
        paragraph = try container.decodeIfPresent(Int.self, forKey: .paragraph)
        turn = try container.decodeIfPresent(String.self, forKey: .turn) ?? ""
        searchKey = "\(word) \(code) \(match) \(before) \(after)".folded
    }
}

struct ResultSnapshot {
    var total = 0
    var speakers: [(String, Int)] = []
    var endings: [(String, Int)] = []
    var sexes: [(String, Int)] = []
    var pronouns: [(String, Int)] = []
    var groups: [(String, Int)] = []
    var forms: [(String, Int)] = []
    var types: [TypeCount] = []
    var groupNames: [String] = []
}

struct TypeCount: Identifiable {
    var id: String { word }
    var word: String
    var count: Int
    var ending: String
}

extension String {
    var folded: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
    }
}

func transcript(_ source: String, gerund: Bool = false) -> Text {
    let pattern = #/<[^>\n]+>/#
    var result = Text("")
    var cursor = source.startIndex

    for match in source.matches(of: pattern) {
        let plain = String(source[cursor..<match.range.lowerBound])
        if !plain.isEmpty {
            result = result + Text(plain)
                .font(.system(size: gerund ? 15 : 15, weight: gerund ? .semibold : .regular, design: .serif))
                .foregroundStyle(gerund ? Theme.gerund : Theme.ink)
        }
        let tag = String(source[match.range])
        result = result + Text(tag)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Theme.muted)
        cursor = match.range.upperBound
    }

    let tail = String(source[cursor...])
    if !tail.isEmpty {
        result = result + Text(tail)
            .font(.system(size: 15, weight: gerund ? .semibold : .regular, design: .serif))
            .foregroundStyle(gerund ? Theme.gerund : Theme.ink)
    }

    return result
}

func highlightedTurn(_ turn: String, match: String) -> Text {
    guard !match.isEmpty else { return transcript(turn) }
    let parts = turn.components(separatedBy: match)
    var result = Text("")
    for index in parts.indices {
        result = result + transcript(parts[index])
        if index < parts.count - 1 {
            result = result + transcript(match, gerund: true)
        }
    }
    return result
}
