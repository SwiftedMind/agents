// By Dennis Müller

import Core
import Foundation

@MainActor
public enum EngineProvider {
  case openAI(configuration: OpenAIEngine.Configuration)
}

public extension EngineProvider {
  /// Convenience provider using `OpenAIEngine.Configuration.defaultConfiguration`.
  /// Call `OpenAIEngine.Configuration.setDefaultConfiguration(...)` before accessing this
  /// if you need to override the default globally (e.g., to inject an API key).
  static let openAI: EngineProvider = .openAI(configuration: OpenAIEngine.Configuration.defaultConfiguration)
}
