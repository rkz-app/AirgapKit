// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AirgapKit",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AirgapKit",
            targets: ["AirgapKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AirgapKit",
            dependencies: [
                .byName(name: "Airgap")
            ]
        ),
        .binaryTarget(
            name: "Airgap",
            url: "https://github.com/rkz-app/airgap/releases/download/v0.0.5/Airgap.xcframework.zip",
            checksum: "d07e46f27b4f0559f5f2892e62b7a4f6437c3a456c569e1b9abc3bfd0c019b78"
        )

    ]
)
