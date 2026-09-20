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

            Text("Identifica los gerundios de las entrevistas y los señala en el resumen, la concordancia y las frecuencias.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("CRÉDITOS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                credit(
                    "Alain Iglesias",
                    linkedIn: URL(string: "https://www.linkedin.com/in/aiherrera")!,
                    site: URL(string: "https://aiherrera.com")!
                )
                credit(
                    "Ailyn Figueroa",
                    linkedIn: URL(string: "https://www.linkedin.com/in/ailyn-figueroa")!,
                    site: URL(string: "https://orcid.org/0000-0002-7976-5940")!,
                    siteLabel: "ORCID"
                )
            }
            .padding(.top, 20)

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

    private func credit(_ name: String, linkedIn: URL, site: URL, siteLabel: String = "Sitio web") -> some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Theme.ink)
            iconLink(linkedIn, label: "LinkedIn de \(name)") {
                LinkedInMark()
            }
            iconLink(site, label: "\(siteLabel) de \(name)") {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 14, height: 14)
            }
        }
    }

    private func iconLink<Icon: View>(_ url: URL, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        Link(destination: url) {
            icon()
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

private struct LinkedInMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(Theme.ink)
            Text("in")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.paper)
                .offset(y: -0.4)
        }
        .frame(width: 14, height: 14)
    }
}
