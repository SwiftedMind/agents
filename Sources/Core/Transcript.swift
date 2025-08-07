// By Dennis Müller

import Foundation
import FoundationModels

public struct Transcript: Sendable, Equatable {
  public var entries: [Entry]

  public init(entries: [Entry] = []) {
    self.entries = entries
  }
}

public extension Transcript {
  enum Entry: Sendable, Identifiable, Equatable {
    case prompt(Prompt)
    case toolCalls(ToolCalls)
    case toolOutput(ToolOutput)
    case response(Response)

    public var id: String {
      switch self {
      case let .prompt(prompt):
        return prompt.id
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

    public var content: String

    public var options: GenerationOptions

    public var responseFormat: Transcript.ResponseFormat?

    public init(
      id: String = UUID().uuidString,
      content: String,
      options: GenerationOptions = .init(),
      responseFormat: Transcript.ResponseFormat?
    ) {
      self.id = id
      self.content = content
      self.options = options
      self.responseFormat = responseFormat
    }
  }

  struct ResponseFormat: Sendable, Equatable {
    public var name: String
    private var schema: GenerationSchema

    public init<Content>(type: Content.Type, name: String) where Content: Generable {
      self.name = name
      schema = type.generationSchema
    }

    public init(schema: GenerationSchema, name: String) {
      self.name = name
      self.schema = schema
    }

    public static func == (a: Transcript.ResponseFormat, b: Transcript.ResponseFormat) -> Bool {
      a.name == b.name
    }
  }

  struct ToolCalls: Sendable, Identifiable, Equatable {
    public var id: String

    public var calls: [ToolCall]

    public init(id: String = UUID().uuidString, calls: [ToolCall]) {
      self.id = id
      self.calls = calls
    }
  }

  struct ToolCall: Sendable, Identifiable, Equatable {
    public var id: String

    public var toolName: String

    public var arguments: GeneratedContent

    public init(id: String, toolName: String, arguments: GeneratedContent) {
      self.id = id
      self.toolName = toolName
      self.arguments = arguments
    }
  }

  struct ToolOutput: Sendable, Identifiable, Equatable {
    public var id: String

    public var toolName: String

    public var segments: [Segment]

    public init(
      id: String = UUID().uuidString,
      toolName: String,
      segments: [Segment]
    ) {
      self.id = id
      self.toolName = toolName
      self.segments = segments
    }
  }

  struct Response: Sendable, Identifiable, Equatable {
    public var id: String

    public var segments: [Segment]

    public init(id: String = UUID().uuidString, segments: [Segment]) {
      self.id = id
      self.segments = segments
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
  }
}
