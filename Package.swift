// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-7230",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 7230",
            targets: ["RFC 7230"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
        .package(path: "../swift-rfc-3986"),
        .package(path: "../swift-rfc-7231")
    ],
    targets: [
        .target(
            name: "RFC 7230",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 7231", package: "swift-rfc-7231")
            ]
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
