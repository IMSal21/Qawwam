// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "QawwamCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "QawwamCore", targets: ["QawwamCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", exact: "1.5.0")
    ],
    targets: [
        .target(
            name: "QawwamCore",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(
            name: "QawwamCoreTests",
            dependencies: ["QawwamCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
