// By Dennis Müller

import Foundation

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Int: PromptRepresentable {}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Double: PromptRepresentable {}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension UUID: PromptRepresentable {
  public var promptRepresentation: Prompt {
    uuidString
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension URL: PromptRepresentable {
  public var promptRepresentation: Prompt {
    absoluteString
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Date: PromptRepresentable {
  public var promptRepresentation: Prompt {
    // Use modern Foundation formatting for a deterministic ISO 8601 output.
    self.formatted(.iso8601)
  }
}

