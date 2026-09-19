import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ayuda")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Andante cuenta en un corpus lo que se le pide en español. Antes de contar, dice qué entendió.")
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                section("El corpus", paragraphs: [
                    "El corpus es la carpeta que elijas. No tiene que ser uno en concreto. Dentro van las entrevistas, en .doc, .rtf o .docx.",
                    "Elegir corpus las lee y las deja listas. Las entrevistas originales no se modifican.",
                    "La primera lectura abre el resumen en gerundios. Es solo el punto de partida: en Consulta se pide otra cosa.",
                ])

                section("Consulta", paragraphs: [
                    "Escribe la petición en español. Andante muestra una frase que empieza por «Entendí». Si esa frase es la que querías, pulsa Buscar.",
                    "El resumen, la concordancia y las frecuencias pasan a esa consulta. No se quedan en gerundios.",
                ], items: [
                    "gerundios",
                    "perífrasis",
                    "gerundio predicativo",
                    "sustantivos",
                    "verbos",
                    "la palabra casa",
                    "termina en ando",
                    "adverbio + gerundio",
                ])

                section("Cómo se arma una petición", paragraphs: [
                    "Perífrasis es un auxiliar —estar, ir, andar, venir, seguir o llevar— seguido de un gerundio. Gerundio predicativo es ser seguido de un gerundio.",
                    "Una estructura une piezas con +, seguido de, antes de, después de, o y. Cada pieza puede ser un sustantivo, adjetivo, adverbio, verbo, gerundio, infinitivo, participio, pronombre, preposición, artículo o conjunción. También una palabra: estar seguido de gerundio.",
                    "Antes de conserva el orden de la frase: «adverbio antes de gerundio» busca el adverbio y luego el gerundio. Después de lo invierte: «gerundio después de adverbio» busca primero el adverbio.",
                    "Entre las dos piezas pueden ir hasta dos palabras. La búsqueda no cruza un cambio de hablante.",
                    "Un verbo en infinitivo se busca conjugado. Una palabra exacta, no: «la palabra casa» es solo casa. La tilde de esa palabra se respeta. Cuándo no es cuando.",
                ])

                section("Los resultados", paragraphs: [
                    "Resumen muestra el total y cómo se reparte por hablante, sexo y grupo de la entrevista. Si la consulta es de gerundios, también por terminación y por pronombre. En las demás, muestra las formas más frecuentes.",
                    "Concordancia lista cada ejemplo con lo de antes y lo de después. Al pulsar una fila se abre el turno completo.",
                    "Frecuencias ordena las formas de la más repetida a la que aparece una vez.",
                    "Los filtros de arriba —forma, hablante, grupo— recortan lo que ya está contado. No lanzan otra consulta. Terminación y pronombre solo aparecen cuando la consulta es de gerundios.",
                ])

                section("Excepciones", paragraphs: [
                    "Una excepción es una palabra que no debe contarse. Se compara la palabra entera y se conserva la tilde.",
                    "Se escriben a mano o se importa un archivo. Importar añade a la lista: no la sustituye. Entran en la siguiente búsqueda.",
                ])

                section("Limpiar", paragraphs: [
                    "Limpiar corpus quita de Andante la concordancia, las estadísticas y los documentos generados. La carpeta de entrevistas no se toca.",
                ])
            }
            .padding(32)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }

    private func section(_ title: String, paragraphs: [String], items: [String] = []) -> some View {
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
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .padding(.top, 2)
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
