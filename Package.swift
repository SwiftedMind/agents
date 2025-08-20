// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftAgent",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(
      name: "SwiftAgent",
      targets: ["SwiftAgent", "OpenAIAgent", "AgentSimulation"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftedMind/swift-openai-responses", branch: "main"),
  ],
  targets: [
    .target(
      name: "Internal"
    ),
    .target(
      name: "SwiftAgent",
      dependencies: ["Internal"]
    ),
    .target(
      name: "OpenAIAgent",
      dependencies: [
        "SwiftAgent",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ]
    ),
    .target(
      name: "AgentSimulation",
      dependencies: [
        "SwiftAgent",
        "Internal",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ]
    ),
    .testTarget(
      name: "SwiftAgentTests",
      dependencies: ["SwiftAgent"]
    ),
  ]
)
