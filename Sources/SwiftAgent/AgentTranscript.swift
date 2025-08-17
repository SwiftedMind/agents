// By Dennis Müller

import Foundation
import FoundationModels

public struct AgentTranscript<Metadata: AdapterMetadata, Context: PromptContext>: Sendable, Equatable {
  public var entries: [Entry]

  public init(entries: [Entry] = []) {
    self.entries = entries
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
    public var content: String
    public var context: [Context]
    public var options: GenerationOptions
    
    package var embeddedPrompt: String
    
    package init(
      id: String = UUID().uuidString,
      content: String,
      context: [Context] = [],
      embeddedPrompt: String,
      options: GenerationOptions = .init()
    ) {
      self.id = id
      self.content = content
      self.context = context
      self.embeddedPrompt = embeddedPrompt
      self.options = options
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
        segment: .structure(AgentTranscript.StructuredSegment(content: generatedContent))
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

// MARK: - Tool Resolver

public extension AgentTranscript {
  func toolResolver<Envelope>(for tools: [any AgentTool<Envelope>]) -> ToolResolver<Envelope> {
    ToolResolver(tools: tools, in: self)
  }
}

public extension AgentTranscript {
  struct ToolResolver<Envelope> {
    private let toolsByName: [String: any AgentTool<Envelope>]
    private let transcriptToolOutputs: [AgentTranscript<Metadata, Context>.ToolOutput]

    init(tools: [any AgentTool<Envelope>], in transcript: AgentTranscript<Metadata, Context>) {
      toolsByName = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
      transcriptToolOutputs = transcript.entries.compactMap { entry in
        switch entry {
        case let .toolOutput(toolOutput):
          return toolOutput
        default:
          return nil
        }
      }
    }

    public func envelope(for call: AgentTranscript<Metadata, Context>.ToolCall) throws -> Envelope {
      guard let tool = toolsByName[call.toolName] else {
        throw ToolResolutionError.unknownTool(name: call.toolName)
      }

      let output = findOutput(for: call.id)
      return try tool.envelope(arguments: call.arguments, output: output)
    }

    private func findOutput(for callId: String) -> GeneratedContent? {
      guard let toolOutput = transcriptToolOutputs.first(where: { $0.callId == callId }) else {
        return nil
      }

      switch toolOutput.segment {
      case let .text(text):
        return GeneratedContent(text.content)
      case let .structure(structure):
        return structure.content
      }
    }
  }

  enum ToolResolutionError: Error, Sendable, Equatable {
    case unknownTool(name: String)
  }
}
