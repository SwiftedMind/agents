// By Dennis Müller

import Foundation

public enum GenerationError: Error, LocalizedError {
  case unexpectedStructuredResponse(UnexpectedStructuredResponseContext)
  case unsupportedToolCalled(UnsupportedToolCalledContext)
  case unknown
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

public extension GenerationError {
  struct UnexpectedStructuredResponseContext: Sendable {
    public init() {}
  }
}
