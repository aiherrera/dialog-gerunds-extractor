import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ayuda")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Andante identifica los gerundios de un corpus de entrevistas y los señala para revisarlos.")
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                section("El corpus", paragraphs: [
                    "El corpus es la carpeta que elijas. Dentro van las entrevistas, en .doc, .rtf o .docx.",
                    "Elegir corpus las lee, marca los gerundios y abre el resumen. Las entrevistas originales no se modifican.",
                    "Limpiar corpus quita de Andante la concordancia, las estadísticas y los documentos generados. La carpeta de entrevistas no se toca.",
                ])

                section("Qué cuenta", paragraphs: [
                    "Un gerundio es una forma en -ando, -iendo o -yendo, con o sin pronombre, como dándole. También cuenta una palabra partida por una marca de transcripción, como conversa<alargamiento/>ndo.",
                    "Una excepción es una palabra que no debe marcarse. Se compara la palabra entera y se conserva la tilde. Se escriben a mano o se importa un archivo. Importar añade a la lista: no la sustituye. Reprocesar vuelve a leer la misma carpeta con la lista actual.",
                ])

                section("Las pantallas", paragraphs: [
                    "Resumen muestra el total y cómo se reparte por hablante, terminación, sexo, pronombre y grupo de la entrevista.",
                    "Concordancia lista cada gerundio con lo de antes y lo de después. Al pulsar una fila se abre el turno.",
                    "Frecuencias ordena las formas de la más repetida a la que aparece una vez.",
                    "Los filtros de arriba recortan lo que ya está contado. No vuelven a leer las entrevistas.",
                ])
            }
            .padding(32)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }

    private func section(_ title: String, paragraphs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            ForEach(paragraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct HelpMenu: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Ayuda de Andante") {
                openWindow(id: "help")
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}
