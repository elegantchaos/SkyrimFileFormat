// swift-tools-version:5.5

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 31/01/2022.
//  All code (c) 2022 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "SkyrimFileFormat",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SkyrimFileFormat",
            targets: ["SkyrimFileFormat"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/AsyncSequenceReader.git", from: "0.1.0"),
        .package(url: "https://github.com/elegantchaos/BinaryCoding.git", .branch("main")),
        .package(url: "https://github.com/elegantchaos/Bytes.git", .branch("float-support")),
        .package(url: "https://github.com/elegantchaos/Coercion.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/ElegantStrings.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.4.5"),
    ],
    targets: [
        .target(
            name: "SkyrimFileFormat",
            dependencies: [
                "AsyncSequenceReader",
                "BinaryCoding",
                "Bytes",
                "Coercion",
                "ElegantStrings",
            ],
            resources: [
            ]
        ),
        
            .testTarget(
                name: "SkyrimFileFormatTests",
                dependencies: ["SkyrimFileFormat", "XCTestExtensions"],
                resources: [
                    .process("Resources/Examples/"),
                    .copy("Resources/Unpacked"),
                ]
            ),
    ]
)
