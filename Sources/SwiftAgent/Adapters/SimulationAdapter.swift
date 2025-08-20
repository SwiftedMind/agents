// By Dennis Müller

import Foundation
import FoundationModels
import Internal
import OpenAI
import OSLog

private func jsonString<T: Encodable>(
  from value: T,
  pretty: Bool = false
) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  if pretty { encoder.outputFormatting.insert(.prettyPrinted) }
  encoder.dateEncodingStrategy = .iso8601

  let data = try encoder.encode(value)
  return String(decoding: data, as: UTF8.self)
}

public extension Encodable {
  func jsonString(pretty: Bool = false) throws -> String {
    try SwiftAgent.jsonString(from: self, pretty: pretty)
  }
}

public enum SimulationStep<Content>: Sendable where Content: Generable, Content: Sendable {
  case reasoning(summary: String)
  case toolRun(tool: any MockableAgentTool)
  case response(content: Content)

  package var toolName: String? {
    switch self {
    case let .toolRun(tool):
      return tool.name
    default:
      return nil
    }
  }
}

@MainActor
public final class SimulationAdapter<Metadata> where Metadata: AdapterMetadata {
  public typealias Model = OpenAI.Model
  public typealias Transcript<ContextReference: PromptContextReference> = AgentTranscript<Metadata, ContextReference>
  
  public init() {}
  
  func respond<Content, Context>(
    to prompt: Transcript<Context>.Prompt,
    generating type: Content.Type,
    including transcript: Transcript<Context>,
    steps: [SimulationStep<Content>]
  ) -> AsyncThrowingStream<Transcript<Context>.Entry, any Error>
    where Content: MockableGenerable, Context: PromptContextReference {
    let setup = AsyncThrowingStream<Transcript<Context>.Entry, any Error>.makeStream()

    // Log the start of a simulated run for visibility
    AgentLog.start(
      model: "simulated",
      toolNames: steps.compactMap(\.toolName),
      promptPreview: prompt.input
    )

    let task = Task<Void, Never> {
      do {
        for (index, step) in steps.enumerated() {
          AgentLog.stepRequest(step: index + 1)
          
          switch step {
          case let .reasoning(summary):
            try await handleReasoning(
              summary: summary,
              continuation: setup.continuation
            )
          case let .toolRun(tool):
            try await handleToolRun(
              tool,
              continuation: setup.continuation
            )
          case let .response(content):
            try await handleResponse(
              content,
              continuation: setup.continuation
            )
          }
        }
      } catch {
        // Surface a clear, user-friendly message
        AgentLog.error(error, context: "respond")
        setup.continuation.finish(throwing: error)
      }

      AgentLog.finish()
      setup.continuation.finish()
    }

    setup.continuation.onTermination = { _ in
      task.cancel()
    }

    return setup.stream
  }
  
  private func handleReasoning<Context>(
    summary: String,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContextReference {
    let entryData = Transcript<Context>.Reasoning(
      summary: [summary],
      encryptedReasoning: "",
      status: .completed,
      metadata: Metadata.Reasoning.simulated
    )
    
    AgentLog.reasoning(summary: [summary])
    
    let entry = Transcript<Context>.Entry.reasoning(entryData)
    continuation.yield(entry)
  }
  
  private func handleToolRun<Context, MockableTool>(
    _ tool: MockableTool,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContextReference, MockableTool: MockableAgentTool {
    let argumentsJSON = try tool.toolType.mockArguments().jsonString()
    let arguments = try GeneratedContent(json: argumentsJSON)
    
    let toolCall = Transcript<Context>.ToolCall(
      toolName: tool.name,
      arguments: arguments,
      status: .completed,
      metadata: .simulated
    )
    
    AgentLog.toolCall(
      name: tool.name,
      callId: "",
      argumentsJSON: argumentsJSON
    )
    
    continuation.yield(.toolCalls(Transcript.ToolCalls(calls: [toolCall])))
    
    do {
      let output = try await tool.toolType.mockOutput()
      
      let toolOutputEntry = Transcript<Context>.ToolOutput(
        toolName: tool.name,
        segment: .structure(AgentTranscript.StructuredSegment(content: output)),
        metadata: .simulated
      )
      
      let transcriptEntry = Transcript<Context>.Entry.toolOutput(toolOutputEntry)
      
      // Try to log as JSON if possible
      AgentLog.toolOutput(
        name: tool.name,
        callId: "",
        outputJSONOrText: output.generatedContent.jsonString
      )
      
      continuation.yield(transcriptEntry)
    } catch {
      AgentLog.error(error, context: "tool_call_failed_\(tool.name)")
      throw ToolCallError(tool: tool, underlyingError: error)
    }
  }
  
  private func handleResponse<Context>(
    _ content: String,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContextReference {
    let response = Transcript<Context>.Response(
      segments: [.text(Transcript.TextSegment(content: content))],
      status: .completed,
      metadata: .simulated
    )
    
    AgentLog.outputMessage(text: content, status: "completed")
    continuation.yield(.response(response))
  }
  
  private func handleResponse<Content, Context>(
    _ content: Content,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: MockableGenerable, Context: PromptContextReference {
    let generatedContent = GeneratedContent(content)
    
    let response = Transcript<Context>.Response(
      segments: [.structure(Transcript.StructuredSegment(content: content))],
      status: .completed,
      metadata: .simulated
    )
    
    AgentLog.outputStructured(json: generatedContent.jsonString, status: "completed")
    continuation.yield(.response(response))
  }
}
