// By Dennis Müller

import Foundation

public struct PromptContext<Source>: Sendable, Equatable where Source: PromptContextSource {
  public init(sources: [Source], linkPreviews: [PromptContextLinkPreview]) {
    self.sources = sources
    self.linkPreviews = linkPreviews
  }

  public static var empty: Self {
    Self(sources: [], linkPreviews: [])
  }

  public var sources: [Source] = []
  public var linkPreviews: [PromptContextLinkPreview] = []
}

public protocol PromptContextSource: Sendable, Equatable {}
public struct NoContext: PromptContextSource {}


// MARK: - Link Previews

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
