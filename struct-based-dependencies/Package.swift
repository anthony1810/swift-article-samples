// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "LocationFeature",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "LocationFeature", targets: ["LocationFeature"]),
    .library(name: "LocationFeatureProtocolBased", targets: ["LocationFeatureProtocolBased"]),
  ],
  targets: [
    .target(name: "LocationFeature"),
    .target(name: "LocationFeatureProtocolBased"),
    .testTarget(name: "LocationFeatureTests", dependencies: ["LocationFeature"]),
    .testTarget(name: "LocationFeatureProtocolBasedTests", dependencies: ["LocationFeatureProtocolBased"]),
  ]
)
