// By Dennis Müller

import Foundation
import FoundationModels

@MainActor
public protocol Provider {
  associatedtype Model: ProviderModel
  associatedtype Configuration: ProviderConfiguration
  associatedtype Metadata: ProviderMetadata
  
  init(
    tools: [any AgentTool],
    instructions: String,
    configuration: Configuration
  )
  
  func respond<Content>(
    to prompt: Core.Transcript<Metadata>.Prompt,
    generating type: Content.Type,
    using model: Model,
    including transcript: Core.Transcript<Metadata>,
    options: Core.GenerationOptions
  ) -> AsyncThrowingStream<Core.Transcript<Metadata>.Entry, any Error> where Content: Generable
}

// MARK: - Provider Model

public protocol ProviderModel {
  static var `default`: Self { get }
}

// MARK: - Metadata

public protocol ProviderMetadata: Codable, Sendable, Equatable {
  associatedtype Reasoning: ReasoningProviderMetadata
}

public protocol ReasoningProviderMetadata: Codable, Sendable, Equatable {
  var reasoningId: String { get set }
}

// MARK: Configuration

@MainActor
public protocol ProviderConfiguration: Sendable {
  /// The default configuration used when no explicit configuration is supplied.
  static var `default`: Self { get set }
  
  /// Override the default configuration used by convenience initializers/providers.
  static func setDefaultConfiguration(_ configuration: Self)
}

public extension ProviderConfiguration {
  /// Overrides the static default configuration used by convenience providers.
  static func setDefaultConfiguration(_ configuration: Self) {
    `default` = configuration
  }
}
