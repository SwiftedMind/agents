# Changelog

## [0.5.0]

### Breaking Changes

- **Adapter-Specific Generation Options**: Replaced the generic `GenerationOptions` struct with adapter-specific generation options. Each adapter now defines its own `GenerationOptions` type as an associated type, providing better type safety and access to adapter-specific parameters:
  ```swift
  // Before
  let options = GenerationOptions(temperature: 0.7, maximumResponseTokens: 1000)
  let response = try await agent.respond(to: prompt, options: options)
  
  // Now
  let options = OpenAIAdapter.GenerationOptions(temperature: 0.7, maxOutputTokens: 1000)
  let response = try await agent.respond(to: prompt, options: options)
  ```

### Added

- **Comprehensive OpenAI Configuration**: The new `OpenAIAdapter.GenerationOptions` provides access to all OpenAI API parameters including:
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

- **Enhanced AgentAdapter Protocol**: Added `GenerationOptions` as an associated type to the `AgentAdapter` protocol, enabling type-safe, adapter-specific configuration

### Enhanced

- **Type Safety**: Generation options are now compile-time validated and specific to each adapter implementation
- **Code Organization**: Moved `OpenAIAdapter.Metadata` to an extension for better code structure

### Migration Guide

1. **Update Generation Options**: Replace generic `GenerationOptions` with adapter-specific options:
   ```swift
   // Update import if needed
   let options = OpenAIAdapter.GenerationOptions(
     temperature: 0.7,
     maxOutputTokens: 1000,
     reasoning: .init(effort: .medium)
   )
   ```

2. **Custom Adapters**: If you have custom adapters, implement the `GenerationOptions` associated type:
   ```swift
   public protocol MyCustomAdapter: AgentAdapter {
     struct GenerationOptions: AdapterGenerationOptions {
       // Your custom options
       public init() {}
     }
   }
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
