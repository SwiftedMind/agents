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

// TODO: Implement properly
// TODO: Implement PromptRepresentable conformance for this type and an array of this type
public struct PromptContextLinkPreview: Sendable, Equatable {
  public var title: String
  public var description: String

  public init(url: URL) async throws {
    title = ""
    description = ""
  }
}
