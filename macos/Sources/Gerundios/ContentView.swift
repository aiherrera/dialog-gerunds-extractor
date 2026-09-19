import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct GerundiosApp: App {
    @State private var store = CorpusStore()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup(Brand.name) {
            ContentView()
                .environment(store)
                .frame(minWidth: 980, minHeight: 640)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Acerca de Andante") {
                    store.showAbout = true
                }
            }
            HelpMenu()
            CommandGroup(after: .newItem) {
                Button("Elegir corpus…") {
                    store.pickCorpus()
                }
                .keyboardShortcut("o")
                .disabled(store.isProcessing)
                Button("Limpiar corpus") {
                    store.clearCorpus()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .disabled(store.isProcessing || store.hits.isEmpty)
                Button("Importar excepciones…") {
                    store.importExclusions()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(store.isProcessing)
                Button("Abrir concordancia…") {
                    store.showImporter = true
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }

        Window("Ayuda de Andante", id: "help") {
            HelpView()
        }
        .defaultSize(width: 680, height: 760)
        .windowResizability(.contentMinSize)
    }
}

struct ContentView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 216)
            Rectangle().fill(Theme.rule).frame(width: 1)
            detail
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .tint(Theme.gerund)
        .fileImporter(
            isPresented: Bindable(store).showImporter,
            allowedContentTypes: [.json]
        ) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    store.load(url)
                    url.stopAccessingSecurityScopedResource()
                } else {
                    store.load(url)
                }
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .sheet(isPresented: Bindable(store).showAbout) {
            AboutView()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Mark(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Brand.name)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 18)

            VStack(spacing: 2) {
                ForEach(AppSection.allCases) { section in
                    Button {
                        store.section = section
                    } label: {
                        Label(section.title, systemImage: section.symbol)
                            .font(.system(size: 13, weight: store.section == section ? .semibold : .regular))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(
                                store.section == section ? Theme.selection : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            Button {
                store.pickCorpus()
            } label: {
                Label("Elegir corpus", systemImage: "folder")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .disabled(store.isProcessing)
            .padding(.horizontal, 10)

            Button {
                store.clearCorpus()
            } label: {
                Label("Limpiar corpus", systemImage: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(store.hits.isEmpty ? Theme.muted : Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .disabled(store.isProcessing || store.hits.isEmpty)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text((store.isProcessing ? store.progress.highlighted : store.snapshot.total).formatted(.number.grouping(.automatic)))
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text(sidebarCaption)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                Button {
                    store.showAbout = true
                } label: {
                    Text("Acerca de")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.sidebar)
    }

    @ViewBuilder
    private var detail: some View {
        VStack(spacing: 0) {
            if let message = store.processError, !store.isProcessing, !store.hits.isEmpty {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.gerund)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .background(Theme.gerund.opacity(0.08))
            }

            if store.isProcessing {
                ProcessingView()
            } else if store.hits.isEmpty, store.section != .exceptions, store.section != .consulta {
                WelcomeView()
            } else {
                switch store.section {
                case .overview:
                    OverviewView()
                case .concordance:
                    ConcordanceView()
                case .frequency:
                    FrequencyView()
                case .exceptions:
                    ExceptionsView()
                case .consulta:
                    ConsultaView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }

    private var sidebarCaption: String {
        if store.isProcessing { return "en proceso" }
        if store.hits.isEmpty { return "sin corpus" }
        return store.resultNoun.replacingOccurrences(of: "\n", with: " ")
    }
}

struct FigureHeader: View {
    @Environment(CorpusStore.self) private var store
    var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if !store.corpusLabel.isEmpty {
                    Text(store.corpusLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(Theme.muted)
                }
                Text(title)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(headline)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FilterBar()
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headline: String {
        let count = store.snapshot.total.formatted(.number.grouping(.automatic))
        let reading = store.queryReading.trimmingCharacters(in: .whitespacesAndNewlines)
        let filters = store.caption == "Todas las entrevistas" ? "" : "  ·  \(store.caption)"
        if reading.isEmpty {
            return "\(count) ejemplos  ·  \(store.caption)"
        }
        return "\(count) ejemplos  ·  \(reading)\(filters)"
    }
}

struct FilterBar: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        let store = Bindable(store)
        HStack(spacing: 18) {
            filterField("Buscar") {
                TextField("forma o entrevista", text: store.query)
                    .textFieldStyle(.plain)
                    .frame(width: 160)
            }
            filterMenu("Hablante") {
                Picker("Hablante", selection: store.speaker) {
                    ForEach(SpeakerFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
            if self.store.showsGerundDetail {
                filterMenu("Terminación") {
                    Picker("Terminación", selection: store.ending) {
                        ForEach(EndingFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }
                filterMenu("Pronombre") {
                    Picker("Pronombre", selection: store.pronoun) {
                        ForEach(PronounFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }
            }
            filterMenu("Grupo") {
                Picker("Grupo", selection: store.group) {
                    Text("Todas").tag("Todas")
                    ForEach(self.store.groupNames, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .onChange(of: self.store.query) { self.store.scheduleRefresh() }
        .onChange(of: self.store.speaker) { self.store.scheduleRefresh() }
        .onChange(of: self.store.ending) { self.store.scheduleRefresh() }
        .onChange(of: self.store.pronoun) { self.store.scheduleRefresh() }
        .onChange(of: self.store.group) { self.store.scheduleRefresh() }
    }

    private func filterField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
            content()
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Theme.rule, lineWidth: 1)
                )
        }
    }

    private func filterMenu<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
            content()
        }
    }
}

struct SpeakerMark: View {
    var speaker: String

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(speaker == "E" ? Theme.gerund : Theme.ink)
            .frame(width: 22, height: 18)
            .background(speaker == "E" ? Theme.gerund.opacity(0.12) : Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var label: String {
        switch speaker {
        case "untagged": "—"
        default: speaker
        }
    }
}
