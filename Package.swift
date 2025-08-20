// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftAgent",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(
      name: "SwiftAgent",
      targets: ["SwiftAgent", "AgentSimulation"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftedMind/swift-openai-responses", branch: "main")
  ],
  targets: [
    .target(
      name: "Internal"
    ),
    .target(
      name: "SwiftAgent",
      dependencies: [
        "Internal",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ]
    ),
    .target(
      name: "AgentSimulation",
      dependencies: ["SwiftAgent"]
    ),
    .testTarget(
      name: "SwiftAgentTests",
      dependencies: ["SwiftAgent"]
    ),
  ]
)
