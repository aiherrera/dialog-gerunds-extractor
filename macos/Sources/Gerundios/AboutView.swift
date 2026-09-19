import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Mark(size: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Brand.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Versión \(Brand.version)  ·  \(Brand.build)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }

            Text(Brand.subtitle)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)

            Text("Consulta el corpus en español. Andante dice qué entendió y cuenta solo eso.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            info("Créditos", lines: [
                "Alain Iglesias",
                "Ailyn Figueroa González",
            ])

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Cerrar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.paper)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Theme.gerund, in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 26)
        }
        .padding(28)
        .frame(width: 420)
        .background(Theme.paper)
        .presentationBackground(Theme.paper)
    }

    private func info(_ title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.top, 20)
    }
}
