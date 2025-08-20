// By Dennis Müller

import Foundation
import FoundationModels

public struct AgentTranscript<Metadata: AdapterMetadata, ContextReference: PromptContextReference>: Sendable, Equatable {
  public var entries: [Entry]

  public init(entries: [Entry] = []) {
    self.entries = entries
  }
}

// MARK: - RandomAccessCollection Conformance

extension AgentTranscript: RandomAccessCollection, RangeReplaceableCollection {
  public var startIndex: Int { entries.startIndex }
  public var endIndex: Int { entries.endIndex }

  public subscript(position: Int) -> Entry {
    entries[position]
  }

  public func index(after i: Int) -> Int {
    entries.index(after: i)
  }

  public func index(before i: Int) -> Int {
    entries.index(before: i)
  }

  public init() {
    entries = []
  }

  public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Element == Entry {
    entries.replaceSubrange(subrange, with: newElements)
  }
}

public extension AgentTranscript {
  enum Entry: Sendable, Identifiable, Equatable {
    case prompt(Prompt)
    case reasoning(Reasoning)
    case toolCalls(ToolCalls)
    case toolOutput(ToolOutput)
    case response(Response)

    public var id: String {
      switch self {
      case let .prompt(prompt):
        return prompt.id
      case let .reasoning(reasoning):
        return reasoning.id
      case let .toolCalls(toolCalls):
        return toolCalls.id
      case let .toolOutput(toolOutput):
        return toolOutput.id
      case let .response(response):
        return response.id
      }
    }
  }

  struct Prompt: Sendable, Identifiable, Equatable {
    public var id: String
    public var input: String
    public var context: PromptContext<ContextReference>
    package var embeddedPrompt: String

    package init(
      id: String = UUID().uuidString,
      input: String,
      context: PromptContext<ContextReference> = .empty,
      embeddedPrompt: String
    ) {
      self.id = id
      self.input = input
      self.context = context
      self.embeddedPrompt = embeddedPrompt
    }
  }

  struct Reasoning: Sendable, Identifiable, Equatable {
    public var id: String
    public var summary: [String]
    public var encryptedReasoning: String?
    public var status: Status?
    package var metadata: Metadata.Reasoning

    package init(
      id: String = UUID().uuidString,
      summary: [String],
      encryptedReasoning: String?,
      status: Status? = nil,
      metadata: Metadata.Reasoning
    ) {
      self.id = id
      self.summary = summary
      self.encryptedReasoning = encryptedReasoning
      self.status = status
      self.metadata = metadata
    }
  }

  enum Status: Sendable, Identifiable, Equatable {
    case completed
    case incomplete
    case inProgress

    public var id: Self { self }
  }

  struct ToolCalls: Sendable, Identifiable, Equatable {
    public var id: String
    public var calls: [ToolCall]

    public init(id: String = UUID().uuidString, calls: [ToolCall]) {
      self.id = id
      self.calls = calls
    }
  }
}

// MARK: - ToolCalls RandomAccessCollection Conformance

extension AgentTranscript.ToolCalls: RandomAccessCollection, RangeReplaceableCollection {
  public var startIndex: Int { calls.startIndex }
  public var endIndex: Int { calls.endIndex }

  public subscript(position: Int) -> AgentTranscript<Metadata, ContextReference>.ToolCall {
    calls[position]
  }

  public func index(after i: Int) -> Int {
    calls.index(after: i)
  }

  public func index(before i: Int) -> Int {
    calls.index(before: i)
  }

  public init() {
    id = UUID().uuidString
    calls = []
  }

  public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Element == AgentTranscript<Metadata, ContextReference>.ToolCall {
    calls.replaceSubrange(subrange, with: newElements)
  }
}

public extension AgentTranscript {
  struct ToolCall: Sendable, Identifiable, Equatable {
    public var id: String
    public var toolName: String
    public var arguments: GeneratedContent
    public var status: Status
    package var metadata: Metadata.ToolCall

    package init(
      id: String = UUID().uuidString,
      toolName: String,
      arguments: GeneratedContent,
      status: Status,
      metadata: Metadata.ToolCall,
    ) {
      self.id = id
      self.toolName = toolName
      self.arguments = arguments
      self.status = status
      self.metadata = metadata
    }
  }

  struct ToolOutput: Sendable, Identifiable, Equatable {
    public var id: String
    public var toolName: String
    public var segment: Segment
    package var metadata: Metadata.ToolOutput

    public init(
      id: String = UUID().uuidString,
      toolName: String,
      segment: Segment,
      metadata: Metadata.ToolOutput
    ) {
      self.id = id
      self.toolName = toolName
      self.segment = segment
      self.metadata = metadata
    }
  }

  struct Response: Sendable, Identifiable, Equatable {
    public var id: String
    public var segments: [Segment]
    public var status: Status
    package var metadata: Metadata.Response

    public init(
      id: String = UUID().uuidString,
      segments: [Segment],
      status: Status,
      metadata: Metadata.Response
    ) {
      self.id = id
      self.segments = segments
      self.status = status
      self.metadata = metadata
    }
  }

  enum Segment: Sendable, Identifiable, Equatable {
    case text(TextSegment)
    case structure(StructuredSegment)

    public var id: String {
      switch self {
      case let .text(textSegment):
        return textSegment.id
      case let .structure(structuredSegment):
        return structuredSegment.id
      }
    }
  }

  struct TextSegment: Sendable, Identifiable, Equatable {
    public var id: String
    public var content: String

    public init(id: String = UUID().uuidString, content: String) {
      self.id = id
      self.content = content
    }
  }

  struct StructuredSegment: Sendable, Identifiable, Equatable {
    public var id: String
    public var content: GeneratedContent

    public init(id: String = UUID().uuidString, content: GeneratedContent) {
      self.id = id
      self.content = content
    }

    public init(id: String = UUID().uuidString, content: some ConvertibleToGeneratedContent) {
      self.id = id
      self.content = content.generatedContent
    }
  }
}
