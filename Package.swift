// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cotty",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "cotty", targets: ["Cotty"]),
    ],
    targets: [
        .systemLibrary(
            name: "CGhosttyVT",
            pkgConfig: "libghostty-vt"
        ),
        .executableTarget(
            name: "Cotty",
            dependencies: ["CGhosttyVT"]
        ),
    ]
)
