# Changelog

## [0.6.0]

### Breaking Changes

- **Modular Architecture**: SwiftAgent has been restructured into separate provider-specific modules. The core `SwiftAgent` framework is now provider-agnostic, with OpenAI functionality moved to the dedicated `OpenAIAgent` module:
  ```swift
  // Before
  import SwiftAgent
  let agent = OpenAIAgent(tools: tools, instructions: "...")
  
  // Now  
  import OpenAIAgent
  let agent = OpenAIAgent(tools: tools, instructions: "...")
  ```

- **Import Changes**: Users must now import the appropriate provider module instead of the core framework:
  - For OpenAI: `import OpenAIAgent` 
  - For custom adapters: `import SwiftAgent`

- **Agent Initializer**: The core `Agent.init(adapter:)` initializer is now public to support external adapter implementations

### Added

- **OpenAIAgent Module**: New dedicated module containing:
  - `OpenAIAdapter` with full OpenAI API integration
  - `OpenAIAgent` typealias for convenient agent creation
  - Convenient initializers with direct API key support:
    ```swift
    // Direct API key configuration
    let agent = OpenAIAgent(
      tools: tools,
      instructions: "...",
      apiKey: "your-api-key"
    )
    
    // Configuration object
    let agent = OpenAIAgent(
      tools: tools, 
      instructions: "...",
      configuration: config
    )
    
    // Default configuration
    let agent = OpenAIAgent(tools: tools, instructions: "...")
    ```

- **Future Provider Support**: The new architecture enables easy addition of other AI providers:
  - `GeminiSwiftAgent` (future)
  - `AnthropicSwiftAgent` (future)
  - Custom provider implementations

- **Enhanced Package Structure**: 
  - Core `SwiftAgent` - Provider-agnostic framework
  - `OpenAIAgent` - OpenAI-specific implementation
  - `AgentSimulation` - Testing and simulation utilities

### Enhanced

- **Provider Agnostic Core**: The core SwiftAgent framework is now completely independent of any AI provider, making it easier to add new providers
- **Cleaner Dependencies**: OpenAI dependencies are isolated to the OpenAIAgent module
- **Better Modularity**: Each provider can have its own specific features and configuration options

### Migration Guide

1. **Update Imports**: Change your import statements to use the appropriate provider module:
   ```swift
   // Replace this
   import SwiftAgent
   
   // With this for OpenAI
   import OpenAIAgent
   
   // Or this for custom adapters
   import SwiftAgent
   ```

2. **Agent Creation**: Agent creation syntax remains the same, but now uses the provider-specific module:
   ```swift
   // This still works the same way
   let agent = OpenAIAgent(tools: tools, instructions: "...")
   
   // But now benefits from new convenience initializers
   let agent = OpenAIAgent(
     tools: tools,
     instructions: "...", 
     apiKey: "your-api-key"
   )
   ```

3. **Configuration**: Configuration methods are now provider-specific and more convenient:
   ```swift
   // Before - global configuration
   let config = OpenAIAdapter.Configuration.direct(apiKey: "...")
   OpenAIAdapter.Configuration.setDefaultConfiguration(config)
   let agent = OpenAIAgent(tools: tools, instructions: "...")
   
   // Now - can configure directly in initializer (recommended)
   let agent = OpenAIAgent(
     tools: tools,
     instructions: "...",
     apiKey: "your-api-key"
   )
   ```

4. **Package Dependencies**: Your Package.swift remains the same - the SwiftAgent package now includes both core and OpenAI modules

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

- **Enhanced PromptContext System**: The `PromptContext` protocol has been replaced with a generic struct wrapper that provides both user-defined context references and SDK-generated context data (like link previews). User types now conform to `PromptContextReference` instead of `PromptContext`:
  ```swift
  // Before
  enum MyContext: SwiftAgent.PromptContext {
    case vectorEmbedding(String)
    case searchResults([String])
  }
  
  // Now
  enum MyContextReference: PromptContextReference {
    case vectorEmbedding(String)
    case searchResults([String])
  }
  ```

- **Updated Agent Generic Parameters**: Agents now use `PromptContextReference` types instead of `PromptContext`:
  ```swift
  // Before
  let agent = OpenAIAgent(supplying: MyContext.self, tools: tools)
  
  // Now
  let agent = OpenAIAgent(supplying: MyContextReference.self, tools: tools)
  ```

- **Simplified AgentTranscript.Prompt**: Removed the `GenerationOptions` field from `AgentTranscript.Prompt` as generation options are now adapter-specific and don't belong in the transcript structure.

### Added

- **Link Preview Support**: The new `PromptContext` struct includes `linkPreviews` that can automatically fetch and include OpenGraph data from URLs in user input (foundation for future URL context extraction)

- **Structured Context Access**: The `PromptContext<Reference>` wrapper provides clean separation between user-defined context references and SDK-generated context data:
  ```swift
  for entry in agent.transcript {
    if case let .prompt(prompt) = entry {
      print("User references: \(prompt.context.references)")
      print("Link previews: \(prompt.context.linkPreviews)")
    }
  }
  ```

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

- **Agent Simulation System**: Introduced the `AgentSimulation` target for testing and development without API calls. The simulation system includes:
  - `simulateResponse` methods that mirror the standard `respond` API
  - `MockableAgentTool` protocol for creating mock tool calls and outputs
  - `SimulatedGeneration` enum supporting tool runs, reasoning, and text or structured responses, simulating model generations
  - Complete transcript compatibility - simulated responses work on the real transcript object, guaranteeing full compatibility with the actual agent
  - Zero API costs during development and testing
  
  ```swift
  import SwiftAgent
  import AgentSimulation
  
  // Create mockable tool wrappers
  struct WeatherToolMock: MockableAgentTool {
    var tool: WeatherTool
    func mockArguments() -> WeatherTool.Arguments { /* mock data */ }
    func mockOutput() async throws -> WeatherTool.Output { /* mock results */ }
  }
  
  // Use simulateResponse instead of respond
  let response = try await agent.simulateResponse(
    to: "What's the weather?",
    generations: [
      .toolRun(tool: WeatherToolMock(tool: WeatherTool())),
      .response(content: "It's sunny!")
    ]
  )
  ```

### Enhanced

- **Type Safety**: Generation options are now compile-time validated and specific to each adapter implementation

### Migration Guide

1. **Update Context Types**: Rename your context protocols to conform to `PromptContextReference` instead of `PromptContext`:
   ```swift
   // Change protocol conformance
   enum MyContextReference: PromptContextReference { ... }
   ```

2. **Update Agent Initialization**: Use the new context reference type:
   ```swift
   let agent = OpenAIAgent(supplying: MyContextReference.self, tools: tools)
   ```

3. **Update Context Usage**: Access context through the new structured format:
   ```swift
   // In prompt builders, context is now PromptContext<MyContextReference>
   ) { input, context in
     // Access user-defined context references
     PromptTag("context", items: context.references)
     // Link previews are available at context.linkPreviews
   }
   ```

4. **Update Generation Options**: Replace generic `GenerationOptions` with adapter-specific options:
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
