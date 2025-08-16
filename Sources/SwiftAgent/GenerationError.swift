// By Dennis Müller

import Foundation

public enum GenerationError: Error, LocalizedError {
  case unexpectedStructuredResponse(UnexpectedStructuredResponseContext)
  case unsupportedToolCalled(UnsupportedToolCalledContext)
  case emptyMessageContent(EmptyMessageContentContext)
  case structuredContentParsingFailed(StructuredContentParsingFailedContext)
  case contentRefusal(ContentRefusalContext)
  case unknown

  public var errorDescription: String? {
    switch self {
    case .unexpectedStructuredResponse:
      return "Received unexpected structured response from model"
    case let .unsupportedToolCalled(context):
      return "Model called unsupported tool: \(context.toolName)"
    case let .emptyMessageContent(context):
      return "Model returned empty content when expecting \(context.expectedType)"
    case let .structuredContentParsingFailed(context):
      return "Failed to parse structured content: \(context.underlyingError)"
    case let .contentRefusal(context):
      return "Model refused to generate content for \(context.expectedType)"
    case .unknown:
      return "Unknown generation error"
    }
  }
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
  
  struct EmptyMessageContentContext: Sendable {
    /// The type that was expected to be generated.
    var expectedType: String
    
    public init(expectedType: String) {
      self.expectedType = expectedType
    }
  }
  
  struct StructuredContentParsingFailedContext: Sendable {
    /// The raw content that failed to parse.
    var rawContent: String
    /// The underlying parsing error.
    var underlyingError: String
    
    public init(rawContent: String, underlyingError: Error) {
      self.rawContent = rawContent
      self.underlyingError = underlyingError.localizedDescription
    }
  }
  
  struct ContentRefusalContext: Sendable {
    /// The type that was being generated when content was refused.
    var expectedType: String
    
    public init(expectedType: String) {
      self.expectedType = expectedType
    }
  }
}
