# Changelog

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
  
  for entry in agent.transcript.entries {
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
