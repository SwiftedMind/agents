# Changelog

## [Upcoming]

### Added

- **Token Usage Tracking and Reporting**: Added token usage monitoring across all AI interactions with logging and programmatic access to usage metrics.

  ```swift
  let response = try await session.respond(to: "What's the weather?")
  
  // Access aggregated token usage from the response
  if let usage = response.tokenUsage {
    print("Total tokens used: \(usage.totalTokens ?? 0)")
    print("Input tokens: \(usage.inputTokens ?? 0)")
    print("Output tokens: \(usage.outputTokens ?? 0)")
    print("Cached tokens: \(usage.cachedTokens ?? 0)")
    print("Reasoning tokens: \(usage.reasoningTokens ?? 0)")
  }
  ```

## [0.5.0]

### Added

- **Simulated Sessions**: Introduced the `SimulatedSession` module for testing and development without API calls. The simulation system includes:
  - `simulateResponse` methods that mirror the standard `respond` API
  - `MockableAgentTool` protocol for creating mock tool calls and outputs
  - `SimulatedGeneration` enum supporting tool runs, reasoning, and text or structured responses, simulating model generations
  - Complete transcript compatibility - simulated responses work on the real transcript object, guaranteeing full compatibility with the actual agent
  - Zero API costs during development and testing
  
  ```swift
  import OpenAISession
  import SimulatedSession
  
  // Create mockable tool wrappers
  struct WeatherToolMock: MockableAgentTool {
    var tool: WeatherTool
    func mockArguments() -> WeatherTool.Arguments { /* mock data */ }
    func mockOutput() async throws -> WeatherTool.Output { /* mock results */ }
  }
  
  // Create an OpenAI session as normal
  let session = ModelSession.openAI(
    tools: [WeatherTool()], // Your actual tool; the mockable tool will be used below
    instructions: "You are a helpful assistant.",
    apiKey: "sk-...",
  )
  
  // And then use simulateResponse instead of respond
  let response = try await session.simulateResponse(
    to: "What's the weather?",
    generations: [
      .toolRun(tool: WeatherToolMock(tool: WeatherTool())),
      .response(content: "It's sunny!")
    ]
  )
  ```
  
- The `PromptContext` protocol has been replaced with a generic struct wrapper that provides both user-written input and app or SDK generated context data (like link previews or vector search results). User types now conform to `PromptContextSource` instead of `PromptContext`:
  ```swift
  // Define your context source
  enum ContextSource: PromptContextSource {
    case vectorSearchResult(String)
    case searchResults([String])
  }
  
  // Create a session with context support and pass the context source
  let session = ModelSession.openAI(tools: tools, context: ContextSource.self, apiKey: "sk-...")
  
  // Respond with context - user input and context are kept separated in the transcript
  let response = try await session.respond(
    to: "What are the key features of SwiftUI?",
    supplying: [
      .vectorSearchResult("SwiftUI declarative syntax..."),
      .searchResults("Apple's official SwiftUI documentation...")
    ]
  ) { input, context in
    PromptTag("context", items: context.sources)
    input
  }
  ```

- **Link Previews in Prompt Context**: The new `PromptContext` struct includes `linkPreviews` that can automatically fetch and include metadata from URLs in user inputs

- **OpenAI Generation Configuration**: The new `OpenAIGenerationOptions` type provides access to OpenAI API parameters including:
  - `include` - Additional outputs like reasoning or logprobs
  - `allowParallelToolCalls` - Control parallel tool execution
  - `reasoning` - Configuration for reasoning-capable models
  - `safetyIdentifier` - Misuse detection identifier
  - `serviceTier` - Request priority and throughput control
  - `toolChoice` - Fine-grained tool selection control
  - `topLogProbs` - Token probability information
  - `topP` - Alternative sampling method
  - `truncation` - Context window handling
  - And more OpenAI-specific options

### Changed

- **Breaking Change**: Restructured the products in the SDK. Each provider now has its own product, e.g. `OpenAISession`
  ```swift
  import OpenAISession
  ```

- **Breaking Change**: Renamed nearly all the types in the SDK to close align with FoundationModels types. `Agent` is now `ModelSession`, and `OpenAIAgent` is now `OpenAISession`:
  ```swift
  import OpenAISession
  
  // Create an OpenAI session through the ModelSession type
  let session = ModelSession.openAI(
    tools: [WeatherTool(), CalculatorTool()],
    instructions: "You are a helpful assistant.",
    apiKey: "sk-...",
  )
  ```
  
- **Breaking Change**: Replaced the generic `GenerationOptions` struct with adapter-specific generation options. Each adapter now defines its own `GenerationOptions` type as an associated type, providing better type safety and access to adapter-specific parameters:
  ```swift
  // Before
  let options = GenerationOptions(temperature: 0.7, maximumResponseTokens: 1000)
  let response = try await agent.respond(to: prompt, options: options)
  
  // Now
  let options = OpenAIGenerationOptions(temperature: 0.7, maxOutputTokens: 1000)
  let response = try await session.respond(to: prompt, options: options)
  ```

## [0.4.1]

### Fixed

- **Agent Text Response Content Formatting**: Fixed an issue with the agent's text response content formatting that could cause malformed responses
- **Tool Resolution**: Fixed a critical bug where tools would never be resolved due to mismatched IDs, ensuring proper tool call execution
- **Tool Resolution Logging**: Improved logging around tool resolution to better debug tool call issues

### Enhanced

- **Collection Protocol Conformance**: Made `AgentTranscript` and `AgentTranscript.ToolCalls` conform to the `Collection` protocol, making it easier to access their `entries` and `calls` properties and work with them using standard Swift collection methods
- **Logging System**: Added general logging methods and enhanced tool resolution logging for better debugging and monitoring
- **Example App**: Added a proper, modern example app with native SwiftUI design that demonstrates the SDK's capabilities

### Other

- **Code Cleanup**: Minor code cleanup and formatting improvements across the codebase
- **UI Modernization**: Redesigned example app UI with new tools and modern SwiftUI patterns

## [0.4.0]

### Breaking Changes

- **Renamed `Provider` to `Adapter`**: The core abstraction for AI model integrations has been renamed from `Provider` to `Adapter` for better clarity. Update all references to use the new naming:
  ```swift
  // Before
  let agent = Agent<OpenAIProvider, Context>()
  
  // Now
  let agent = Agent<OpenAIAdapter, Context>()
  ```

- **Renamed `Transcript` to `AgentTranscript`**: To avoid naming conflicts with FoundationModels, the `Transcript` type has been renamed to `AgentTranscript`:
  ```swift
  // Before
  public var transcript: Transcript
  
  // Now  
  public var transcript: AgentTranscript<Adapter.Metadata, Context>
  ```

### Added

- **Prompt Context System**: Introduced a new `PromptContext` protocol that enables separation of user input from contextual information (such as vector embeddings or retrieved documents). This provides cleaner transcript organization and better prompt augmentation:
  ```swift
  enum PromptContext: SwiftAgent.PromptContext {
    case vectorEmbedding(String)
    case documentContext(String)
  }
  
  let agent = OpenAIAgent(supplying: PromptContext.self, tools: tools)
  
  // User input and context are now separated in the transcript
  let response = try await agent.respond(
    to: "What is the weather like?", 
    supplying: [.vectorEmbedding("relevant weather data")]
  ) { input, context in
    PromptTag("context", items: context)
    input
  }
  ```

- **Tool Resolver**: Added a powerful type-safe tool resolution system that combines tool calls with their outputs. The `ToolResolver` enables compile-time access to tool arguments and outputs:
  ```swift
  // Define a resolved tool run enum
  enum ResolvedToolRun {
    case getFavoriteNumbers(AgentToolRun<GetFavoriteNumbersTool>)
  }
  
  // Tools must implement the resolve method
  func resolve(_ run: AgentToolRun<GetFavoriteNumbersTool>) -> ResolvedToolRun {
    .getFavoriteNumbers(run)
  }
  
  // Use the tool resolver in your UI code
  let toolResolver = agent.transcript.toolResolver(for: tools)
  
  for entry in agent.transcript {
    if case let .toolCalls(toolCalls) = entry {
      for toolCall in toolCalls.calls {
        let resolvedTool = try toolResolver.resolve(toolCall)
        switch resolvedTool {
        case let .getFavoriteNumbers(run):
          print("Count:", run.arguments.count)
          if let output = run.output {
            print("Numbers:", output.numbers)
          }
        }
      }
    }
  }
  ```

- **Convenience Initializers**: Added streamlined initializers that reduce generic complexity. The new `OpenAIAgent` typealias and convenience initializers make agent creation more ergonomic:
  ```swift
  // Simplified initialization with typealias
  let agent = OpenAIAgent(supplying: PromptContext.self, tools: tools)
  
  // No context needed
  let agent = OpenAIAgent(tools: tools)
  
  // Even simpler for basic usage
  let agent = OpenAIAgent()
  ```

### Enhanced

- **AgentTool Protocol**: Extended the `AgentTool` protocol with an optional `ResolvedToolRun` associated type to support the new tool resolver system
- **Type Safety**: Improved compile-time type safety for tool argument and output access through the tool resolver
- **Transcript Organization**: Better separation of concerns in transcript entries, with user input and context clearly distinguished

### Migration Guide

1. **Update Provider references**: Replace all instances of `Provider` with `Adapter` in your code
2. **Update Transcript references**: Replace `Transcript` with `AgentTranscript` where needed
3. **Consider adopting PromptContext**: If you're currently building prompts with embedded context outside the agent, consider migrating to the new `PromptContext` system for cleaner separation
4. **Adopt Tool Resolver**: For better type safety in UI code that displays tool runs, implement the `resolve` method in your tools and use the transcript's `toolResolver`
5. **Use convenience initializers**: Simplify your agent initialization code using the new `OpenAIAgent` typealias and convenience initializers
