// By Dennis Müller

import Foundation
import Internal

@MainActor
public protocol AgentAdapter {
  associatedtype Model: AdapterModel
  associatedtype Configuration: AdapterConfiguration
  associatedtype Metadata: AdapterMetadata

  init(tools: [any AgentTool], instructions: String, configuration: Configuration)

  func respond<Content, Embeddable>(
    to prompt: Transcript<Metadata, Embeddable>.Prompt,
    generating type: Content.Type,
    using model: Model,
    including transcript: Transcript<Metadata, Embeddable>,
    options: GenerationOptions
  ) -> AsyncThrowingStream<Transcript<Metadata, Embeddable>.Entry, any Error> where Content: FoundationGenerable, Embeddable: PromptEmbeddable
}

// MARK: - Model

public protocol AdapterModel {
  static var `default`: Self { get }
}

// MARK: - Metadata

public protocol AdapterMetadata: Codable, Sendable, Equatable {
  associatedtype Reasoning: Codable, Sendable, Equatable
  associatedtype Response: Codable, Sendable, Equatable
}

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
