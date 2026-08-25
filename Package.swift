// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CodexRoadmapPet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexPet", targets: ["CodexPet"])
    ],
    targets: [
        .executableTarget(
            name: "CodexPet",
            path: "Sources/CodexPet"
        ),
        .testTarget(
            name: "CodexPetTests",
            dependencies: ["CodexPet"],
            path: "Tests/CodexPetTests"
        )
    ]
)
