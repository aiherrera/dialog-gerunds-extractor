import SwiftUI

struct ExceptionsView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Theme.rule).frame(height: 1)
            if store.exclusions.isEmpty {
                empty("La lista está vacía. Añade una forma o importa un archivo.")
            } else if store.visibleExclusions.isEmpty {
                empty("Ninguna excepción coincide con la búsqueda.")
            } else {
                list
            }
        }
        .background(Theme.paper)
    }

    private var header: some View {
        let store = Bindable(store)
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NO SE MARCAN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.muted)
                Text("Excepciones")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(caption)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                Text("La comparación es la palabra entera y conserva la tilde. Reprocesar vuelve a leer la misma carpeta con esta lista.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Theme.muted)
            }

            HStack(spacing: 10) {
                field {
                    TextField("añadir una forma", text: store.exclusionDraft)
                        .textFieldStyle(.plain)
                        .onSubmit { self.store.addDraftExclusion() }
                }
                .frame(width: 220)

                Button {
                    self.store.addDraftExclusion()
                } label: {
                    Text("Añadir")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.paper)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.gerund, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(self.store.isProcessing || self.store.exclusionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    self.store.importExclusions()
                } label: {
                    Label("Importar", systemImage: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.plain)
                .disabled(self.store.isProcessing)

                Button {
                    self.store.reprocess()
                } label: {
                    Text("Reprocesar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.55), in: Capsule())
                        .overlay(Capsule().stroke(Theme.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!self.store.canReprocess)
                .help("Vuelve a leer el corpus con la lista actual")

                Spacer(minLength: 12)

                field {
                    TextField("buscar", text: store.exclusionQuery)
                        .textFieldStyle(.plain)
                        .frame(width: 140)
                }
            }

            if let note = self.store.exclusionNote {
                Text(note)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(store.visibleExclusions.enumerated()), id: \.element) { index, word in
                    HStack(spacing: 16) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 28, alignment: .trailing)
                        Text(word)
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 12)
                        Button {
                            store.removeExclusion(word)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isProcessing)
                        .help("Quitar \(word)")
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 7)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.rule).frame(height: 1)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func empty(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 15, design: .serif))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(28)
    }

    private var caption: String {
        let total = store.exclusions.count
        let forms = total == 1 ? "1 forma" : "\(total.formatted(.number.grouping(.automatic))) formas"
        let needle = store.exclusionQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return forms }
        let shown = store.visibleExclusions.count
        return "\(shown.formatted(.number.grouping(.automatic))) de \(forms)"
    }

    private func field<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
