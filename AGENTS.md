# SwiftAgent

**Native Swift SDK for building autonomous AI agents with Apple's FoundationModels design philosophy**

SwiftAgent simplifies AI agent development by providing a clean, intuitive API that handles all the complexity of agent loops, tool execution, and adapter communication. Inspired by Apple's FoundationModels framework, it brings the same elegant, declarative approach to cross-platform AI agent development.

## Project Overview

SwiftAgent is a Swift Package that provides:
- **Core SDK** (`Sources/SwiftAgent/`): The main ModelSession framework with adapter architecture
- **OpenAI Adapter** (`Sources/OpenAI/`): Official OpenAI integration with GPT models
- **Simulation Adapter** (`Sources/Simulation/`): Mock adapter for testing and development
- **Internal Utilities** (`Sources/Internal/`): Shared utilities and logging infrastructure
- **Example App** (`Examples/Example App/`): A working iOS app demonstrating SDK usage
- **Guidelines** (`guidelines/`): General rules and guidelines for working on this project as well as technical documentation

## Project Structure

### Core SDK (`Sources/SwiftAgent/`)
- **`ModelSession.swift`** - Main ModelSession class for AI interactions
- **`SwiftAgentConfiguration.swift`** - Global configuration and logging settings
- **`Agent/`** - Agent system components:
  - **`AgentAdapter.swift`** - Protocol for AI provider adapters
  - **`AgentGenerationError.swift`** - Error handling for generation failures
  - **`AgentTool.swift`** - Tool definition protocols and implementations
  - **`AgentToolCallError.swift`** - Tool-specific error handling
  - **`AgentToolResolver.swift`** - Type-safe tool resolution system
  - **`AgentTranscript.swift`** - Conversation history and transcript management
- **`Networking/`** - HTTP client and networking infrastructure:
  - **`HTTPClient.swift`** - HTTP client implementation
  - **`HTTPErrorMessageExtractor.swift`** - Error message extraction
  - **`NetworkLog.swift`** - Network request/response logging
  - **`SSE.swift`** - Server-Sent Events support
- **`Prompt Builder/`** - DSL for building structured prompts:
  - **`PromptBuilder.swift`** - Main prompt building DSL
  - **`PromptBuiltins.swift`** - Built-in prompt components
- **`Prompt Context/`** - Context injection system:
  - **`PromptContext.swift`** - Context management
  - **`PromptContextLinkPreview.swift`** - Link preview support

### OpenAI Integration (`Sources/OpenAI/`)
- **`OpenAIAdapter.swift`** - OpenAI API adapter implementation
- **`OpenAIConfiguration.swift`** - Configuration for OpenAI services
- **`OpenAIGenerationOptions.swift`** - Generation options and parameters
- **`OpenAIGenerationOptionsError.swift`** - OpenAI-specific error handling
- **`OpenAISession.swift`** - OpenAI session management

### Simulation Support (`Sources/Simulation/`)
- **`MockableProtocols.swift`** - Protocols for mocking in tests
- **`SimulatedGeneration.swift`** - Simulated AI generation responses
- **`SimulatedModelSession.swift`** - Mock ModelSession for testing
- **`SimulationAdapter.swift`** - Simulation adapter implementation

### Testing (`Tests/`)
- **`SwiftAgentTests/`** - Core SDK unit tests using Swift Testing
- **`SwiftAgentTests.xctestplan`** - Test plan configuration

## Quick Navigation for AI Agents

### Common Entry Points
- **Start here for core logic**: `Sources/SwiftAgent/ModelSession.swift:1` - Main ModelSession implementation
- **Tool development**: `Sources/SwiftAgent/Agent/AgentTool.swift:1` - Tool protocols and examples
- **Adding new adapters**: `Sources/SwiftAgent/Agent/AgentAdapter.swift:1` - Adapter protocol definition
- **OpenAI integration**: `Sources/OpenAI/OpenAIAdapter.swift:1` - OpenAI adapter implementation
- **Example usage**: `Examples/Example App/RootView.swift:1` - Working ModelSession implementation in UI

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
  simulatorName: "iPhone 16 Pro"
})
```

#### Build Example App

- Replace {working_directory} with the current working directory

```
xcodebuild__build_sim_name_ws({
  workspacePath: "{working_directory}/SwiftAgent.xcworkspace",
  scheme: "ExampleApp",
  simulatorName: "iPhone 16 Pro"
})
```

#### Run Tests

- Replace {working_directory} with the current working directory

```
xcodebuild__test_sim_name_ws({
  workspacePath: "{working_directory}/SwiftAgent.xcworkspace",
  scheme: "SwiftAgentTests",
  simulatorName: "iPhone 16 Pro",
  useLatestOS: true,
  extraArgs: ["-testPlan", "SwiftAgentTests"]
})
```
