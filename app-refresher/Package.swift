// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "TeamSyncFeature",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "TeamSyncFeature", targets: ["TeamSyncFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/anthony1810/ScreenStateKit.git", from: "1.3.1"),
  ],
  targets: [
    .target(
      name: "TeamSyncFeature",
      dependencies: [.product(name: "ScreenStateKit", package: "ScreenStateKit")]
    ),
    .testTarget(
      name: "TeamSyncFeatureTests",
      dependencies: [
        "TeamSyncFeature",
        .product(name: "ScreenStateKit", package: "ScreenStateKit"),
      ]
    ),
  ]
)
