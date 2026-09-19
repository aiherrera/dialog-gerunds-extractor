// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Gerundios",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Gerundios",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
