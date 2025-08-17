// By Dennis Müller

import Foundation
import FoundationModels

// MARK: - Tool Resolver

public extension AgentTranscript {
  func toolResolver<ResolvedToolRun>(for tools: [any AgentTool<ResolvedToolRun>]) -> AgentToolResolver<Metadata, Context, ResolvedToolRun> {
    AgentToolResolver(tools: tools, in: self)
  }
}

public struct AgentToolResolver<Metadata: AdapterMetadata, Context: PromptContext, ResolvedToolRun> {
  private let toolsByName: [String: any AgentTool<ResolvedToolRun>]
  private let transcriptToolOutputs: [AgentTranscript<Metadata, Context>.ToolOutput]

  init(tools: [any AgentTool<ResolvedToolRun>], in transcript: AgentTranscript<Metadata, Context>) {
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

  public func resolve(_ call: AgentTranscript<Metadata, Context>.ToolCall) throws -> ResolvedToolRun {
    guard let tool = toolsByName[call.toolName] else {
      throw AgentToolResolutionError.unknownTool(name: call.toolName)
    }

    let output = findOutput(for: call.id)
    return try tool.resolvedTool(arguments: call.arguments, output: output)
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

enum AgentToolResolutionError: Error, Sendable, Equatable {
  case unknownTool(name: String)
}
