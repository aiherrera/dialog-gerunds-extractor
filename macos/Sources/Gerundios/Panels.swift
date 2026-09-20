import Charts
import SwiftUI

struct FrequencyView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            FigureHeader(title: "Frecuencias")
            Rectangle().fill(Theme.rule).frame(height: 1)

            if store.snapshot.types.isEmpty {
                Text("No hay resultados con este filtro.")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(28)
            } else {
                let maxCount = store.snapshot.types.first?.count ?? 1
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.snapshot.types.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 28, alignment: .trailing)
                                Text(item.word)
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.gerund)
                                    .lineLimit(store.showsGerundDetail ? 1 : 2)
                                    .frame(minWidth: 140, maxWidth: store.showsGerundDetail ? 180 : 320, alignment: .leading)
                                if store.showsGerundDetail, !item.ending.isEmpty {
                                    Text("-\(item.ending)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.muted)
                                        .frame(width: 64, alignment: .leading)
                                }
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(Theme.bar)
                                    .scaleEffect(
                                        x: max(0.004, CGFloat(item.count) / CGFloat(maxCount)),
                                        y: 1,
                                        anchor: .leading
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 8)
                                Text(item.count.formatted(.number.grouping(.automatic)))
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 48, alignment: .trailing)
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
        }
        .background(Theme.paper)
    }
}

struct OverviewView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                FigureHeader(title: "Resumen")
                    .padding(.horizontal, -28)

                HStack(alignment: .lastTextBaseline, spacing: 14) {
                    Text(store.snapshot.total.formatted(.number.grouping(.automatic)))
                        .font(.system(size: 64, weight: .semibold, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                    Text(store.resultNoun)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(1)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: true, vertical: true)
                }

                HStack(alignment: .top, spacing: 22) {
                    DonutCard(title: "Hablante", rows: store.snapshot.speakers, total: store.snapshot.total)
                    if store.showsGerundDetail {
                        DonutCard(title: "Terminación", rows: store.snapshot.endings, total: store.snapshot.total)
                    } else if !store.snapshot.forms.isEmpty {
                        DonutCard(title: "Formas", rows: store.snapshot.forms, total: store.snapshot.total)
                    }
                    DonutCard(title: "Sexo", rows: store.snapshot.sexes, total: store.snapshot.total)
                }

                if store.showsGerundDetail {
                    StackedShare(title: "Pronombre", rows: store.snapshot.pronouns, total: store.snapshot.total)
                }

                ShareBars(
                    title: "Grupo de la entrevista",
                    rows: store.snapshot.groups,
                    total: store.snapshot.total,
                    scaleToMax: true
                )

            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.paper)
    }
}

private struct Slice: Identifiable {
    var label: String
    var count: Int
    var color: Color
    var id: String { label }
}

private struct DonutCard: View {
    var title: String
    var rows: [(String, Int)]
    var total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)
            if slices.isEmpty {
                Text("—")
                    .foregroundStyle(Theme.muted)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Chart(slices) { slice in
                            SectorMark(
                                angle: .value("Cantidad", slice.count),
                                innerRadius: .ratio(0.64),
                                angularInset: 1.4
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(2)
                        }
                        .chartLegend(.hidden)
                        .frame(width: 132, height: 132)

                        if let lead = slices.first {
                            VStack(spacing: 0) {
                                Text(percent(lead.count))
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.ink)
                                Text(lead.label)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(1)
                                    .frame(width: 68)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(slices) { slice in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(slice.color)
                                    .frame(width: 7, height: 7)
                                Text(slice.label)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(percent(slice.count))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.muted)
                            }
                            .font(.system(size: 12, design: .serif))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var slices: [Slice] {
        rows.enumerated().map { index, row in
            Slice(label: row.0, count: row.1, color: Theme.series[index % Theme.series.count])
        }
    }

    private func percent(_ count: Int) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", Double(count) / Double(total) * 100)
    }
}

private struct StackedShare: View {
    var title: String
    var rows: [(String, Int)]
    var total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)
            if !slices.isEmpty {
                GeometryReader { proxy in
                    let gap = CGFloat(max(slices.count - 1, 0)) * 3
                    let usable = max(0, proxy.size.width - gap)
                    HStack(spacing: 3) {
                        ForEach(slices) { slice in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(slice.color)
                                .frame(width: max(4, usable * fraction(slice.count)))
                        }
                    }
                }
                .frame(height: 22)

                HStack(spacing: 18) {
                    ForEach(slices) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 7, height: 7)
                            Text(slice.label)
                                .foregroundStyle(Theme.ink)
                            Text(slice.count.formatted(.number.grouping(.automatic)))
                                .monospacedDigit()
                                .foregroundStyle(Theme.ink)
                            Text(percent(slice.count))
                                .monospacedDigit()
                                .foregroundStyle(Theme.muted)
                        }
                        .font(.system(size: 13, design: .serif))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var slices: [Slice] {
        rows.enumerated().map { index, row in
            Slice(label: row.0, count: row.1, color: Theme.series[index % Theme.series.count])
        }
    }

    private func fraction(_ count: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }

    private func percent(_ count: Int) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", Double(count) / Double(total) * 100)
    }
}

private func sectionTitle(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.system(size: 10, weight: .semibold))
        .tracking(0.8)
        .foregroundStyle(Theme.muted)
}

private struct ShareBars: View {
    var title: String
    var rows: [(String, Int)]
    var total: Int
    var scaleToMax: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
            if scaleToMax {
                Text("La barra compara los grupos entre sí. El porcentaje es sobre el total.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }

            ForEach(rows, id: \.0) { row in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.0)
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 12)
                        Text(row.1.formatted(.number.grouping(.automatic)))
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
                        Text(share(row.1))
                            .frame(width: 52, alignment: .trailing)
                            .foregroundStyle(Theme.muted)
                    }
                    .font(.system(size: 14, design: .serif))

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.06))
                            Capsule()
                                .fill(Theme.gerund)
                                .frame(width: max(2, proxy.size.width * fraction(row.1)))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fraction(_ count: Int) -> CGFloat {
        let basis = scaleToMax ? (rows.map(\.1).max() ?? 1) : max(total, 1)
        guard basis > 0 else { return 0 }
        return CGFloat(count) / CGFloat(basis)
    }

    private func share(_ count: Int) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", Double(count) / Double(total) * 100)
    }
}
