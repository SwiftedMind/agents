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
