// By Dennis Müller

import Foundation

public struct PromptContext<Reference>: Sendable, Equatable where Reference: PromptContextReference {
  public init(references: [Reference], linkPreviews: [PromptContextLinkPreview]) {
    self.references = references
    self.linkPreviews = linkPreviews
  }
  
  public static var empty: Self {
    Self(references: [], linkPreviews: [])
  }
  
  public var references: [Reference] = []
  public var linkPreviews: [PromptContextLinkPreview] = []
}

public protocol PromptContextReference: Sendable, Equatable {}
public struct EmptyPromptContextReference: PromptContextReference {}

public struct PromptContextLinkPreview: Sendable, Equatable {
  public var title: String
  public var description: String
  
  public init(url: URL) async throws {
    self.title = ""
    self.description = ""
  }
}
