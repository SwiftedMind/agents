// By Dennis Müller

import Foundation
import FoundationModels

/*

 TODO: Document the reason why Transcript HAS to be tied to its original provider:
 Say you start out with OpenAI o3. You get an encrypted_content property containing the raw encoded reasoning you can pass back to continue the conversation with the full reasoning history. Obviously you won't be able to decode this yourself and give it to another model, that's why it's encrypted in the first place.

 */

public struct Transcript<Metadata: ProviderMetadata>: Sendable, Equatable {
  public var entries: [Entry]

  public init(entries: [Entry] = []) {
    self.entries = entries
  }
}

public extension Transcript {
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

  struct ToolCall: Sendable, Identifiable, Equatable {
    public var id: String
    public var callId: String
    public var toolName: String
    public var arguments: GeneratedContent
    public var status: Status

    public init(id: String = UUID().uuidString, callId: String, toolName: String, arguments: GeneratedContent, status: Status) {
      self.id = id
      self.callId = callId
      self.toolName = toolName
      self.arguments = arguments
      self.status = status
    }
  }

  struct ToolOutput: Sendable, Identifiable, Equatable {
    public var id: String
    public var callId: String
    public var toolName: String
    public var segment: Segment

    public init(
      id: String = UUID().uuidString,
      callId: String,
      toolName: String,
      segment: Segment
    ) {
      self.id = id
      self.callId = callId
      self.toolName = toolName
      self.segment = segment
    }

    public static func generatedContent(
      _ generatedContent: some ConvertibleToGeneratedContent,
      callId: String,
      toolName: String,
    ) -> Self {
      ToolOutput(
        callId: callId,
        toolName: toolName,
        segment: .structure(Transcript.StructuredSegment(content: generatedContent))
      )
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
