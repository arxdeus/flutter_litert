// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_litert",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-litert", targets: ["flutter_litert"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_litert",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
