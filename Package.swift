// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mazewar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MazewarApp", targets: ["MazewarApp"])
    ],
    targets: [
        .target(name: "MazewarCore"),
        .executableTarget(
            name: "MazewarApp",
            dependencies: ["MazewarCore"],
            linkerSettings: [.linkedFramework("MultipeerConnectivity")]
        ),
        .testTarget(name: "MazewarCoreTests", dependencies: ["MazewarCore"])
    ]
)
