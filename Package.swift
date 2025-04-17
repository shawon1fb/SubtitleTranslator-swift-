// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SubtitleTranslator",
    platforms: [
        .macOS(.v13)  // Lower minimum version for better compatibility
    ],
    products: [
        .executable(
            name: "SubtitleTranslator",
            targets: ["SubtitleTranslator"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "SubtitleTranslator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
              //  .process("Resources/")  // If you have any resources
            ]
        ),
        .testTarget(
            name: "SubtitleTranslatorTests",
            dependencies: ["SubtitleTranslator"]
        )
    ]
)
