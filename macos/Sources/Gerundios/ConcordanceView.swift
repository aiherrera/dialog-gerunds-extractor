import SwiftUI

struct ConcordanceView: View {
    @Environment(CorpusStore.self) private var store
    @State private var shown = 200

    var body: some View {
        VStack(spacing: 0) {
            FigureHeader(title: "Concordancia")
            Rectangle().fill(Theme.rule).frame(height: 1)
            columnLabels
            Rectangle().fill(Theme.rule).frame(height: 1)

            if !store.hitsReady, store.snapshot.total > 0 {
                Text("Cargando ejemplos…")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(28)
            } else if store.visible.isEmpty {
                Text("No hay resultados con este filtro.")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(28)
            } else {
                let rows = Array(store.visible.prefix(shown))
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(rows) { hit in
                            ConcordanceRow(hit: hit, wide: !store.showsGerundDetail)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 6)
                                .background(store.selection == hit.id ? Theme.selection : Color.clear)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(Theme.rule).frame(height: 1)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.select(hit.id)
                                }
                                .onAppear {
                                    if hit.id == rows.last?.id, shown < store.visible.count {
                                        shown += 200
                                    }
                                }
                        }
                    }
                }
            }

            if let hit = store.selectedHit {
                Rectangle().fill(Theme.rule).frame(height: 1)
                TurnPane(hit: hit, turn: store.selectedTurn)
            }
        }
        .background(Theme.paper)
        .onChange(of: store.revision) {
            shown = 200
        }
    }

    private var columnLabels: some View {
        HStack(spacing: 0) {
            Text("ENTREVISTA")
                .frame(width: ConcordanceMetrics.interview, alignment: .leading)
            Text("")
                .frame(width: ConcordanceMetrics.speaker, height: 12)
            Text("ANTES")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 10)
            Text(store.showsGerundDetail ? "GERUNDIO" : "FORMA")
                .frame(width: ConcordanceMetrics.form(wide: !store.showsGerundDetail), alignment: .leading)
            Text("DESPUÉS")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .font(.system(size: 10, weight: .semibold))
        .tracking(0.7)
        .foregroundStyle(Theme.muted)
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private enum ConcordanceMetrics {
    static let interview: CGFloat = 132
    static let speaker: CGFloat = 36

    static func form(wide: Bool) -> CGFloat {
        wide ? 280 : 156
    }
}

struct ConcordanceRow: View {
    var hit: Hit
    var wide = false

    var body: some View {
        HStack(spacing: 0) {
            Text(hit.code)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(width: ConcordanceMetrics.interview, alignment: .leading)
            SpeakerMark(speaker: hit.speaker)
                .frame(width: ConcordanceMetrics.speaker, alignment: .leading)
            transcript(hit.before)
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 10)
            transcript(hit.match, gerund: true)
                .lineLimit(wide ? 2 : 1)
                .truncationMode(.middle)
                .frame(width: ConcordanceMetrics.form(wide: wide), alignment: .leading)
            transcript(hit.after)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .padding(.vertical, 2)
    }
}

struct TurnPane: View {
    var hit: Hit
    var turn: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(hit.code)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                SpeakerMark(speaker: hit.speaker)
                Text(speakerName)
                    .foregroundStyle(Theme.muted)
                if !hit.clitic.isEmpty {
                    Text("·  \(hit.clitic)")
                        .foregroundStyle(Theme.gerund)
                }
                Spacer()
                Text(hit.group.isEmpty ? hit.ending : "\(hit.group)  ·  -\(hit.ending)")
                    .foregroundStyle(Theme.muted)
            }
            .font(.system(size: 12))

            highlightedTurn(displayTurn, match: hit.match)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .background(Theme.paperDeep)
    }

    private var displayTurn: String {
        if !turn.isEmpty { return turn }
        return "\(hit.before) \(hit.match) \(hit.after)"
    }

    private var speakerName: String {
        switch hit.speaker {
        case "I": "Informante"
        case "E": "Entrevistador"
        case "untagged": "Sin etiqueta"
        default: hit.speaker
        }
    }
}
