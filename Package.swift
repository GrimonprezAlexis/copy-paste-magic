// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CopyPasteMagic",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CopyPasteMagic",
            path: "Sources/CopyPasteMagic",
            resources: [
                .copy("../../Resources/Info.plist")
            ]
        )
    ]
)
