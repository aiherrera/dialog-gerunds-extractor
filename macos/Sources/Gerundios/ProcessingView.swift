import AppKit
import SwiftUI

struct Mark: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let image = BrandIcon.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                Text("ndo")
                    .font(.system(size: size * 0.34, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.paper)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Theme.rule, lineWidth: 1)
        )
    }
}

enum BrandIcon {
    static let image: NSImage? = load()

    static func load() -> NSImage? {
        let manager = FileManager.default
        var urls: [URL] = []
        if let bundled = Bundle.main.url(forResource: "andante-icon", withExtension: "png") {
            urls.append(bundled)
        }

        var starts = [Bundle.main.bundleURL, URL(fileURLWithPath: manager.currentDirectoryPath)]
        if let executable = Bundle.main.executableURL {
            starts.append(executable.deletingLastPathComponent())
        }

        for start in starts {
            var current = start
            for _ in 0..<8 {
                urls.append(current.appendingPathComponent("Resources/andante-icon.png"))
                urls.append(current.appendingPathComponent("macos/Resources/andante-icon.png"))
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path { break }
                current = parent
            }
        }

        for url in urls where manager.fileExists(atPath: url.path) {
            if let image = NSImage(contentsOf: url) { return image }
        }
        return nil
    }
}

struct ProcessingView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            stage
            Rectangle().fill(Theme.rule).frame(width: 1)
            ledger
        }
        .background(Theme.paper)
    }

    private var stage: some View {
        let progress = store.progress
        return VStack(alignment: .leading, spacing: 0) {
            Mark(size: 72)

            Text(Brand.name.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(Theme.muted)
                .padding(.top, 22)

            Text(progress.currentCode.isEmpty ? "Abriendo el corpus" : progress.currentCode)
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 8)

            Text(progress.currentFile.isEmpty ? progress.corpusName : progress.currentFile)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .padding(.top, 4)

            ProgressView(value: fraction)
                .tint(Theme.gerund)
                .padding(.top, 28)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(progress.completed)")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text("de \(max(progress.total, progress.completed))")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 12)
                Text(progress.highlighted.formatted(.number.grouping(.automatic)))
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(store.resultNoun.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.top, 16)
            .animation(.snappy(duration: 0.25), value: progress.highlighted)
            .animation(.snappy(duration: 0.25), value: progress.completed)

            if !progress.words.isEmpty {
                Text(progress.words.joined(separator: "   "))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.gerund)
                    .lineLimit(2)
                    .padding(.top, 22)
                    .id(progress.words.joined())
                    .transition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var ledger: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ENTREVISTAS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.progress.files) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(item.code)
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(item.failed ? Theme.muted : Theme.ink)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(item.failed ? "—" : item.highlighted.formatted(.number.grouping(.automatic)))
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .monospacedDigit()
                                .foregroundStyle(item.failed ? Theme.gerund : Theme.ink)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .frame(width: 280)
        .background(Theme.paperDeep.opacity(0.45))
    }

    private var fraction: Double {
        guard store.progress.total > 0 else { return 0 }
        return Double(store.progress.completed) / Double(store.progress.total)
    }
}

struct WelcomeView: View {
    @Environment(CorpusStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Mark(size: 96)

            Text(Brand.name)
                .font(.system(size: 48, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)

            Text(Brand.subtitle)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)

            Button {
                store.pickCorpus()
            } label: {
                Text("Elegir corpus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.paper)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.gerund, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 28)

            if let message = store.processError ?? store.loadError {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: 460, alignment: .leading)
                    .padding(.top, 16)
            }

            Spacer(minLength: 0)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }
}
