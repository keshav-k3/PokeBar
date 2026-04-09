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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.1")
    ],
    targets: [
        .executableTarget(
            name: "PokeBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "PokeBar",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
