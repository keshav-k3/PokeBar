// swift-tools-version: 5.9
//
// PokeBar — https://github.com/keshav-k3/PokeBar

import PackageDescription

let package = Package(
    name: "PokeBar",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "PokeBar",
            targets: ["PokeBar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PokeBar",
            dependencies: [],
            path: "PokeBar",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
