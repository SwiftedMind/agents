// By Dennis Müller

import Foundation
import FoundationModels
import Internal

@MainActor
public protocol AgentAdapter {
  associatedtype GenerationOptions: AdapterGenerationOptions
  associatedtype Model: AdapterModel
  associatedtype Configuration: AdapterConfiguration
  associatedtype Metadata: AdapterMetadata

  init(tools: [any AgentTool], instructions: String, configuration: Configuration)

  func respond<Content, ContextReference>(
    to prompt: AgentTranscript<Metadata, ContextReference>.Prompt,
    generating type: Content.Type,
    using model: Model,
    including transcript: AgentTranscript<Metadata, ContextReference>,
    options: GenerationOptions
  ) -> AsyncThrowingStream<AgentTranscript<Metadata, ContextReference>.Entry, any Error> where Content: Generable, ContextReference: PromptContextReference
}

// MARK: - GenerationOptions

public protocol AdapterGenerationOptions {
  init()
}

// MARK: - Model

public protocol AdapterModel {
  static var `default`: Self { get }
}

// MARK: - Metadata

public protocol AdapterMetadata {
  associatedtype Reasoning: ReasoningAdapterMetadata
  associatedtype ToolCall: ToolCallAdapterMetadata
  associatedtype ToolOutput: ToolOutputAdapterMetadata
  associatedtype Response: ResponseAdapterMetadata
}

public protocol ReasoningAdapterMetadata: Codable, Sendable, Equatable {
  var reasoningId: String { get }
}

public protocol ToolCallAdapterMetadata: Codable, Sendable, Equatable {
  /// The provider specific identifier for the tool call.
  ///
  /// For example, OpenAI uses a "call_" prefixed id, while Anthropic uses a "toolu_" prefixed id.
  var toolCallId: String { get }
}

public protocol ToolOutputAdapterMetadata: Codable, Sendable, Equatable {
  /// The provider specific identifier for the tool call.
  ///
  /// For example, OpenAI uses a "call_" prefixed id, while Anthropic uses a "toolu_" prefixed id.
  var toolCallId: String { get }
}

public protocol ResponseAdapterMetadata: Codable, Sendable, Equatable {}

// MARK: Configuration

@MainActor
public protocol AdapterConfiguration: Sendable {
  /// The default configuration used when no explicit configuration is supplied.
  static var `default`: Self { get set }

  /// Override the default configuration used by convenience initializers/providers.
  static func setDefaultConfiguration(_ configuration: Self)
}

public extension AdapterConfiguration {
  /// Overrides the static default configuration used by convenience providers.
  static func setDefaultConfiguration(_ configuration: Self) {
    `default` = configuration
  }
}
