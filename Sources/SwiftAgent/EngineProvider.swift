// By Dennis Müller

import Core
import Engines
import Foundation

@MainActor
public enum EngineProvider {
  case openAI(configuration: OpenAIEngine.Configuration)
}
