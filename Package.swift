// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Statdock",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Statdock", targets: ["Statdock"]),
    ],
    targets: [
        .target(name: "SystemKit", path: "Sources/SystemKit"),
        .executableTarget(
            name: "Statdock",
            dependencies: ["SystemKit"],
            path: "Sources/Statdock"
        ),
    ]
)
