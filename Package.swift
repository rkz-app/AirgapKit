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
            url: "https://github.com/rkz-app/airgap/releases/download/v0.1.2/Airgap.xcframework.zip",
            checksum: "fdf0097123182224b9279e051c1ad1baacac570ee34d6da8541e2a8acbe35a6d"
        )

    ]
)
