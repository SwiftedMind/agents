# SwiftAgent

## General Instructions

- When making changes to the code, ALWAYS build the SDK to check for compilation errors
- When making changes to code used in the app, always consider if any of the @docs/ files have to be updated
- Use 2 spaces for indentation and tabs
- In SwiftUI views, always place private properties on top of the non-private ones, and the non-private ones directly above the initializer

## Resources

- @docs/modern-swift.md - Guidelines on modern SwiftUI and how to build things with it
- @docs/swift-testing.md - An overview of the Swift Testing framework
- @docs/tests.md - Guidelines on writing unit tests for the SDK

## Development Commands

### Building and Testing

- Build and test the SDK in `SwiftAgent.xcworkspace` using the `XcodeBuildMCP` mcp
- DO NOT build or test using `swift build` or `swift test` as it will not work (due to iOS dependencies)

#### Build SDK

```
xcodebuild__build_sim_name_ws({
  workspacePath: "/Users/swiftedmind/Code/SwiftAgent/SwiftAgent.xcworkspace",
  scheme: "SwiftAgent",
  simulatorName: "iPhone 16"
})
```

#### Run Tests

```
xcodebuild__test_sim_name_ws({
  workspacePath: "/Users/swiftedmind/Code/SwiftAgent/SwiftAgent.xcworkspace",
  scheme: "SwiftAgentTests",
  simulatorName: "iPhone 16",
  useLatestOS: true,
  extraArgs: ["-testPlan", "SwiftAgentTests"]
})
```
