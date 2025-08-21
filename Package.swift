// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftAgent",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(name: "OpenAISession", targets: ["OpenAISession", "SimulatedSession", "SwiftAgent"]),
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
      name: "OpenAISession",
      dependencies: [
        "SwiftAgent",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ],
      path: "Sources/OpenAI",
    ),
    .target(
      name: "SimulatedSession",
      dependencies: [
        "SwiftAgent",
        "Internal",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ],
      path: "Sources/Simulation",
    ),
    .testTarget(
      name: "SwiftAgentTests",
      dependencies: ["SwiftAgent"]
    ),
  ]
)
