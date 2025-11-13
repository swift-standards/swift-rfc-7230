// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-7230",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "RFC 7230",
            targets: ["RFC 7230"]
        )
    ],
    targets: [
        .target(
            name: "RFC 7230"
        ),
        .testTarget(
            name: "RFC 7230 Tests",
            dependencies: ["RFC 7230"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
