// By Dennis Müller

import Foundation

public enum GenerationError: Error, LocalizedError {
  case unsupportedToolCalled(UnsupportedToolCalledContext)
}

public extension GenerationError {
  struct UnsupportedToolCalledContext: Sendable {
    /// The name of the tool that the model tried to call.
    var toolName: String
    
    public init(toolName: String) {
      self.toolName = toolName
    }
  }
}
