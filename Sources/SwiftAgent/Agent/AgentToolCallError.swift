// By Dennis Müller

import Foundation
import FoundationModels

public struct AgentToolCallError: Error, LocalizedError {
  /// The tool that produced the error.
  public var tool: any FoundationModels.Tool

  /// The underlying error that was thrown during a tool call.
  public var underlyingError: any Error

  /// Creates a tool call error
  ///
  /// - Parameters:
  ///   - tool: The tool that produced the error.
  ///   - underlyingError: The underlying error.
  public init(tool: any Tool, underlyingError: any Error) {
    self.tool = tool
    self.underlyingError = underlyingError
  }

  /// A string representation of the error description.
  public var errorDescription: String? {
    let toolName = String(describing: type(of: tool))
    let underlyingDescription = (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
    return "Tool '\(toolName)' failed: \(underlyingDescription)"
  }
}
