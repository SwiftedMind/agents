// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftAgent",
  platforms: [
    .iOS(.v26),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "SwiftAgent",
      targets: ["SwiftAgent"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftedMind/swift-openai-responses", branch: "main")
  ],
  targets: [
    .target(
      name: "Core"
    ),
    .target(
      name: "SwiftAgent",
      dependencies: [
        "Core",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ]
    ),
    .testTarget(
      name: "SwiftAgentTests",
      dependencies: ["SwiftAgent"]
    ),
  ]
)
