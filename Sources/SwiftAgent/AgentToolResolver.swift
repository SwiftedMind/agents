// By Dennis Müller

import Foundation
import FoundationModels
import Internal
import OSLog

// MARK: - Tool Resolver

public extension AgentTranscript {
  func toolResolver<ResolvedToolRun>(for tools: [any AgentTool<ResolvedToolRun>]) -> AgentToolResolver<ContextReference, ResolvedToolRun> {
    AgentToolResolver(tools: tools, in: self)
  }
}

public struct AgentToolResolver<ContextReference: PromptContextReference, ResolvedToolRun> {
  public typealias ToolCall = AgentTranscript<ContextReference>.ToolCall

  private let toolsByName: [String: any AgentTool<ResolvedToolRun>]
  private let transcriptToolOutputs: [AgentTranscript<ContextReference>.ToolOutput]

  init(tools: [any AgentTool<ResolvedToolRun>], in transcript: AgentTranscript<ContextReference>) {
    toolsByName = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    transcriptToolOutputs = transcript.compactMap { entry in
      switch entry {
      case let .toolOutput(toolOutput):
        return toolOutput
      default:
        return nil
      }
    }
  }

  public func resolve(_ call: ToolCall) throws -> ResolvedToolRun {
    guard let tool = toolsByName[call.toolName] else {
      let availableTools = toolsByName.keys.sorted().joined(separator: ", ")
      AgentLog.error(
        AgentToolResolutionError.unknownTool(name: call.toolName),
        context: "Tool resolution failed. Available tools: \(availableTools)"
      )
      throw AgentToolResolutionError.unknownTool(name: call.toolName)
    }

    let output = findOutput(for: call)

    do {
      let resolvedTool = try tool.resolvedTool(arguments: call.arguments, output: output)
      return resolvedTool
    } catch {
      AgentLog.error(error, context: "Tool resolution for '\(call.toolName)'")
      throw error
    }
  }

  private func findOutput(for call: ToolCall) -> GeneratedContent? {
    guard let toolOutput = transcriptToolOutputs.first(
      where: { $0.callId == call.callId }) else {
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
