// By Dennis Müller

import Foundation
import FoundationModels

@MainActor
public protocol Engine {
  associatedtype Configuration: EngineConfiguration
  init(
    tools: [any SwiftAgentTool],
    instructions: String,
    configuration: Configuration
  )

  func respond(
    to prompt: Core.Transcript.Prompt,
    transcript: Core.Transcript
  ) -> AsyncThrowingStream<Core.Transcript.Entry, any Error>
}

/// A configuration type for an Engine.
/// Conforming types provide a default configuration and a way to override it.
@MainActor
public protocol EngineConfiguration: Sendable {
  /// The default configuration used when no explicit configuration is supplied.
  static var defaultConfiguration: Self { get }
  /// Override the default configuration used by convenience initializers/providers.
  static func setDefaultConfiguration(_ configuration: Self)
}
