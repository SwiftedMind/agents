// By Dennis Müller

import Foundation
import FoundationModels
@_exported import SwiftAgent

/// An AI agent specialized for OpenAI models and services.
/// This agent provides seamless integration with OpenAI's API through the OpenAIAdapter.
public typealias OpenAIAgent<ContextReference: PromptContextReference> = Agent<OpenAIAdapter, ContextReference>

// MARK: - Convenience Initializers

public extension Agent where Adapter == OpenAIAdapter {
  /// Creates a new OpenAI agent with the specified tools and instructions.
  /// Uses the default OpenAI configuration which requires environment setup or manual configuration.
  ///
  /// - Parameters:
  ///   - tools: The tools available to the agent
  ///   - instructions: System instructions for the agent
  convenience init(tools: [any AgentTool], instructions: String) {
    let adapter = OpenAIAdapter(
      tools: tools,
      instructions: instructions,
      configuration: .default
    )
    self.init(adapter: adapter)
  }

  /// Creates a new OpenAI agent with custom configuration.
  ///
  /// - Parameters:
  ///   - tools: The tools available to the agent
  ///   - instructions: System instructions for the agent
  ///   - configuration: Custom OpenAI adapter configuration
  convenience init(
    tools: [any AgentTool],
    instructions: String,
    configuration: OpenAIAdapter.Configuration
  ) {
    let adapter = OpenAIAdapter(
      tools: tools,
      instructions: instructions,
      configuration: configuration
    )
    self.init(adapter: adapter)
  }

  /// Creates a new OpenAI agent configured for direct API access.
  ///
  /// - Parameters:
  ///   - tools: The tools available to the agent
  ///   - instructions: System instructions for the agent
  ///   - apiKey: OpenAI API key
  ///   - baseURL: Optional custom base URL (defaults to OpenAI's API)
  ///   - responsesPath: Optional custom responses path
  convenience init(
    tools: [any AgentTool],
    instructions: String,
    apiKey: String,
    baseURL: URL = URL(string: "https://api.openai.com")!,
    responsesPath: String = "/v1/responses"
  ) {
    let configuration = OpenAIAdapter.Configuration.direct(
      apiKey: apiKey,
      baseURL: baseURL,
      responsesPath: responsesPath
    )

    let adapter = OpenAIAdapter(
      tools: tools,
      instructions: instructions,
      configuration: configuration
    )
    self.init(adapter: adapter)
  }
}
