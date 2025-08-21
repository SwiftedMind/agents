// By Dennis Müller

import Foundation
import FoundationModels
import Internal
import OpenAI
import OSLog
import Public

@MainActor
public struct SimulationAdapter {
  public typealias Model = OpenAI.Model
  public typealias Transcript<Context: PromptContextSource> = AgentTranscript<Context>

  public struct Configuration: Sendable {
    /// The delay between simulated model generations.
    public var generationDelay: Duration

    public init(generationDelay: Duration = .milliseconds(500)) {
      self.generationDelay = generationDelay
    }
  }

  private let configuration: Configuration

  public init(configuration: Configuration = Configuration()) {
    self.configuration = configuration
  }

  func respond<Content, Context>(
    to prompt: Transcript<Context>.Prompt,
    generating type: Content.Type,
    generations: [SimulatedGeneration<Content>]
  ) -> AsyncThrowingStream<Transcript<Context>.Entry, any Error>
  where Content: MockableGenerable, Context: PromptContextSource {
    let setup = AsyncThrowingStream<Transcript<Context>.Entry, any Error>.makeStream()

    // Log the start of a simulated run for visibility
    AgentLog.start(
      model: "simulated",
      toolNames: generations.compactMap(\.toolName),
      promptPreview: prompt.input
    )

    let task = Task<Void, Never> {
      do {
        for (index, generation) in generations.enumerated() {
          AgentLog.stepRequest(step: index + 1)
          try await Task.sleep(for: configuration.generationDelay)

          switch generation {
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
            if let content = content as? String {
              try await handleStringResponse(content, continuation: setup.continuation)
            } else {
              try await handleStructuredResponse(content, continuation: setup.continuation)
            }
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
  ) async throws where Context: PromptContextSource {
    let entryData = Transcript<Context>.Reasoning(
      id: UUID().uuidString,
      summary: [summary],
      encryptedReasoning: "",
      status: .completed
    )

    AgentLog.reasoning(summary: [summary])

    let entry = Transcript<Context>.Entry.reasoning(entryData)
    continuation.yield(entry)
  }

  private func handleToolRun<Context, MockedTool>(
    _ toolMock: MockedTool,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContextSource, MockedTool: MockableAgentTool {
    let callId = UUID().uuidString
    let argumentsJSON = try toolMock.mockArguments().jsonString()
    let arguments = try GeneratedContent(json: argumentsJSON)

    let toolCall = Transcript<Context>.ToolCall(
      id: UUID().uuidString,
      callId: callId,
      toolName: toolMock.tool.name,
      arguments: arguments,
      status: .completed,
    )

    AgentLog.toolCall(
      name: toolMock.tool.name,
      callId: callId,
      argumentsJSON: argumentsJSON
    )

    continuation.yield(.toolCalls(Transcript.ToolCalls(calls: [toolCall])))

    do {
      let output = try await toolMock.mockOutput()

      let toolOutputEntry = Transcript<Context>.ToolOutput(
        id: UUID().uuidString,
        callId: callId,
        toolName: toolMock.tool.name,
        segment: .structure(AgentTranscript.StructuredSegment(content: output)),
      )

      let transcriptEntry = Transcript<Context>.Entry.toolOutput(toolOutputEntry)

      // Try to log as JSON if possible
      AgentLog.toolOutput(
        name: toolMock.tool.name,
        callId: callId,
        outputJSONOrText: output.generatedContent.jsonString
      )

      continuation.yield(transcriptEntry)
    } catch {
      AgentLog.error(error, context: "tool_call_failed_\(toolMock.tool.name)")
      throw AgentToolCallError(tool: toolMock.tool, underlyingError: error)
    }
  }

  private func handleStringResponse<Context>(
    _ content: String,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContextSource {
    let response = Transcript<Context>.Response(
      id: UUID().uuidString,
      segments: [.text(Transcript.TextSegment(content: content))],
      status: .completed,
    )

    AgentLog.outputMessage(text: content, status: "completed")
    continuation.yield(.response(response))
  }

  private func handleStructuredResponse<Content, Context>(
    _ content: Content,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: MockableGenerable, Context: PromptContextSource {
    let generatedContent = GeneratedContent(content)

    let response = Transcript<Context>.Response(
      id: UUID().uuidString,
      segments: [.structure(Transcript.StructuredSegment(content: content))],
      status: .completed,
    )

    AgentLog.outputStructured(json: generatedContent.jsonString, status: "completed")
    continuation.yield(.response(response))
  }
}
