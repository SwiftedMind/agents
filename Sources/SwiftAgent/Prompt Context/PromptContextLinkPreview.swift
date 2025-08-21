// By Dennis Müller

import Foundation

public struct PromptContextLinkPreview: Sendable, Equatable {
  /// The original URL from user input before any redirects
  public var originalURL: URL

  /// The final URL after following redirects
  public var url: URL

  /// The title of the linked content
  public var title: String?

  public init(originalURL: URL, url: URL, title: String? = nil) {
    self.originalURL = originalURL
    self.url = url
    self.title = title
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PromptContextLinkPreview: PromptRepresentable {
  public var promptRepresentation: Prompt {
    var attributes: [String: String] = [
      "url": url.absoluteString,
    ]

    if originalURL != url {
      attributes["original_url"] = originalURL.absoluteString
    }

    if let title = title {
      attributes["title"] = title
    }

    return Prompt {
      PromptTag("link-preview", attributes: attributes)
    }
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Array: PromptRepresentable where Element == PromptContextLinkPreview {
  public var promptRepresentation: Prompt {
    guard !isEmpty else {
      return Prompt.empty
    }

    return Prompt {
      PromptTag("link-previews") {
        for linkPreview in self {
          linkPreview
        }
      }
    }
  }
}
