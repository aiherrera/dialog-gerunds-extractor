import SwiftUI

struct ConsultaView: View {
    @Environment(CorpusStore.self) private var store

    private let shortcuts = [
        "gerundios",
        "perífrasis",
        "gerundio predicativo",
        "sustantivos",
        "verbos",
        "adverbio + gerundio",
        "la palabra casa",
        "termina en ando",
    ]

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QUÉ QUIERES BUSCAR")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(Theme.muted)
                    Text("Consulta")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Escríbelo en español. Andante dice qué entendió antes de contar.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }

                HStack(alignment: .center, spacing: 12) {
                    TextField("adverbio + gerundio", text: $store.consultaDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .onSubmit { Task { await store.runConsulta() } }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.ink.opacity(0.18), lineWidth: 1)
                        )

                    Button {
                        Task { await store.runConsulta() }
                    } label: {
                        Text("Buscar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.paper)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                store.consultaOk ? Theme.gerund : Theme.gerund.opacity(0.35),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.consultaOk || store.isProcessing)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ATAJOS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.muted)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(shortcuts, id: \.self) { shortcut in
                            Button {
                                store.consultaDraft = shortcut
                                store.scheduleInterpret()
                            } label: {
                                Text(shortcut)
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundStyle(Theme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        store.consultaDraft == shortcut ? Theme.selection : Theme.paperDeep,
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if store.consultaOk {
                    Text("Entendí: \(store.consultaReading)")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.paperDeep, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if !store.consultaMessage.isEmpty, !store.consultaDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(store.consultaMessage)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Theme.gerund)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("TAMBIÉN")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.muted)
                    Text("Una estructura se arma con +, seguido de, antes de o después de. Cada pieza puede ser un sustantivo, adjetivo, adverbio, verbo, gerundio, infinitivo, participio, pronombre, preposición, artículo o conjunción. O una palabra: estar seguido de gerundio.")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
        .onChange(of: store.consultaDraft) {
            store.scheduleInterpret()
        }
        .onAppear {
            if store.consultaDraft.isEmpty {
                store.consultaDraft = "gerundios"
            }
            store.scheduleInterpret()
        }
    }
}
