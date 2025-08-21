// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftAgent",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .library(name: "OpenAISession", targets: ["OpenAISession", "SimulatedSession"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftedMind/swift-openai-responses", branch: "main"),
  ],
  targets: [
    .target(
      name: "Internal"
    ),
    .target(
      name: "Public",
      dependencies: ["Internal"]
    ),
    .target(
      name: "OpenAISession",
      dependencies: [
        "Public",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ],
      path: "Sources/OpenAI",
    ),
    .target(
      name: "SimulatedSession",
      dependencies: [
        "Public",
        "Internal",
        .product(name: "OpenAI", package: "swift-openai-responses"),
      ],
      path: "Sources/Simulation",
    ),
    .testTarget(
      name: "SwiftAgentTests",
      dependencies: ["Public"]
    ),
  ]
)
