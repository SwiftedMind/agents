# SwiftAgent

**Native Swift SDK for building autonomous AI agents with Apple's FoundationModels design philosophy**

SwiftAgent simplifies AI agent development by providing a clean, intuitive API that handles all the complexity of agent loops, tool execution, and adapter communication. Inspired by Apple's FoundationModels framework, it brings the same elegant, declarative approach to cross-platform AI agent development.

## Project Overview

SwiftAgent is a Swift Package that provides:
- **Core SDK** (`Sources/SwiftAgent/`): The main agent framework with adapter support for OpenAI and extensible to other providers
- **Example App** (`Examples/Example App/`): A working iOS app demonstrating SDK usage
- **Guidelines** (`guidelines/`): General rules and guidelines for working on this project as well as technical documentation

## Project Structure

### Core SDK (`Sources/SwiftAgent/`)
- **`Agent.swift`** - Main agent class and core loop implementation
- **`SwiftAgentConfiguration.swift`** - Global configuration and logging settings
- **`AgentTool.swift`** - Tool definition protocols and implementations
- **`AgentToolResolver.swift`** - Type-safe tool resolution system
- **`AgentTranscript.swift`** - Conversation history and transcript management
- **`PromptContext.swift`** - Context injection system for prompts
- **`Adapters/`** - AI provider adapters (OpenAI, extensible)
- **`Networking/`** - HTTP client and error handling
- **`PromptBuilder/`** - DSL for building structured prompts

### Testing (`Tests/`)
- **`SwiftAgentTests/`** - Core SDK unit tests using Swift Testing
- **`SwiftAgentTests.xctestplan`** - Test plan configuration

## Quick Navigation for AI Agents

### Common Entry Points
- **Start here for core logic**: `Sources/SwiftAgent/Agent.swift:1` - Main agent implementation
- **Tool development**: `Sources/SwiftAgent/AgentTool.swift:1` - Tool protocols and examples
- **Adding new adapters**: `Sources/SwiftAgent/Adapters/AgentAdapter.swift:1` - Adapter protocol definition
- **Example usage**: `Examples/Example App/RootView.swift:1` - Working agent implementation in UI

### When Working on Different Areas
- **Core agent logic**: Focus on `Sources/SwiftAgent/Agent.swift` and related files
- **Tool system**: Check `AgentTool.swift`, `AgentToolResolver.swift`, and existing tool examples
- **UI/Example app**: Work in `Examples/Example App/` directory
- **Networking/HTTP**: Modify files in `Sources/SwiftAgent/Networking/`
- **Testing**: Add tests to `Tests/SwiftAgentTests/` using Swift Testing framework

## General Instructions

- Always follow the best practices of naming things in Swift
- ALWAYS use clear names for types and variables, don't just use single letters or abbreviations. Clarity is key!
- Use clean formatting
- Always make use of todo lists to keep track of your plan and work, unless the task is trivial or very quick
- When making changes to the code, ALWAYS build the SDK to check for compilation errors
- When making changes to code used in the app, always consider if any of the @guidelines/ files have to be updated
- Use 2 spaces for indentation and tabs
- In SwiftUI views, always place private properties on top of the non-private ones, and the non-private ones directly above the initializer
- ALWAYS use the documentation-writer agent when writing documentation or docstrings, or when working on a readme or changelog
- ALWAYS use the swift-test-writer agent when working with unit tests

### Todos

- Always place todos in the @guidelines/todos directory
- Each todo is placed in its own file where it can be specified and thought about until it is completed

## Resources

- @guidelines/modern-swift.md - Guidelines on modern SwiftUI and how to build things with it
- @guidelines/swift-testing.md - An overview of the Swift Testing framework
- @guidelines/tests.md - Guidelines on writing unit tests for the SDK

## Development Commands

### Building and Testing

- Build and test the SDK in `SwiftAgent.xcworkspace` using the `XcodeBuildMCP` mcp
- DO NOT build or test using `swift build` or `swift test` as it will not work (due to iOS dependencies)

#### Build SDK

- Replace {working_directory} with the current working directory

```
xcodebuild__build_sim_name_ws({
  workspacePath: "{working_directory}/SwiftAgent.xcworkspace",
  scheme: "SwiftAgent",
  simulatorName: "iPhone 16"
})
```

#### Build Example App

- Replace {working_directory} with the current working directory

```
xcodebuild__build_sim_name_ws({
  workspacePath: "{working_directory}/SwiftAgent.xcworkspace",
  scheme: "ExampleApp",
  simulatorName: "iPhone 16"
})
```

#### Run Tests

- Replace {working_directory} with the current working directory

```
xcodebuild__test_sim_name_ws({
  workspacePath: "{working_directory}/SwiftAgent.xcworkspace",
  scheme: "SwiftAgentTests",
  simulatorName: "iPhone 16",
  useLatestOS: true,
  extraArgs: ["-testPlan", "SwiftAgentTests"]
})
```
