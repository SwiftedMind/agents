// By Dennis Müller

import Foundation
import FoundationModels
import SwiftAgent

public extension Agent {
  
  private var simulationAdapter: SimulationAdapter {
    SimulationAdapter()
  }
  
  @discardableResult
  func simulateResponse(
    to prompt: String,
    steps: [SimulationStep<String>]
  ) async throws -> Response<String> {
    let transcriptPrompt = Transcript.Prompt(input: prompt, embeddedPrompt: prompt)
    let promptEntry = Transcript.Entry.prompt(transcriptPrompt)
    transcript.append(promptEntry)

    let stream = simulationAdapter.respond(
      to: transcriptPrompt,
      generating: String.self,
      including: transcript,
      steps: steps
    )
    var responseContent: [String] = []
    var addedEntities: [Transcript.Entry] = []

    for try await entry in stream {
      transcript.append(entry)
      addedEntities.append(entry)

      if case let .response(response) = entry {
        for segment in response.segments {
          switch segment {
          case let .text(textSegment):
            responseContent.append(textSegment.content)
          case .structure:
            break
          }
        }
      }
    }

    return AgentResponse<Adapter, ContextReference, String>(
      content: responseContent.joined(separator: "\n"),
      addedEntries: addedEntities
    )
  }

  @discardableResult
  func simulateResponse<Content>(
    to prompt: String,
    steps: [SimulationStep<Content>]
  ) async throws -> Response<Content> where Content: MockableGenerable {
    let transcriptPrompt = Transcript.Prompt(input: prompt, embeddedPrompt: prompt)
    let promptEntry = Transcript.Entry.prompt(transcriptPrompt)
    transcript.append(promptEntry)

    let stream = simulationAdapter.respond(
      to: transcriptPrompt,
      generating: Content.self,
      including: transcript,
      steps: steps
    )
    var addedEntities: [Transcript.Entry] = []

    for try await entry in stream {
      transcript.append(entry)
      addedEntities.append(entry)

      if case let .response(response) = entry {
        for segment in response.segments {
          switch segment {
          case .text:
            break
          case let .structure(structuredSegment):
            return try AgentResponse<Adapter, ContextReference, Content>(
              content: Content(structuredSegment.content),
              addedEntries: addedEntities
            )
          }
        }
      }
    }

    let errorContext = GenerationError.UnexpectedStructuredResponseContext()
    throw GenerationError.unexpectedStructuredResponse(errorContext)
  }

  @discardableResult
  func simulateResponse(
    to prompt: SwiftAgent.Prompt,
    steps: [SimulationStep<String>]
  ) async throws -> Response<String> {
    try await simulateResponse(to: prompt.formatted(), steps: steps)
  }

  @discardableResult
  func simulateResponse<Content>(
    to prompt: SwiftAgent.Prompt,
    steps: [SimulationStep<Content>]
  ) async throws -> Response<Content> where Content: MockableGenerable {
    try await simulateResponse(to: prompt.formatted(), steps: steps)
  }

  @discardableResult
  func simulateResponse(
    steps: [SimulationStep<String>],
    @SwiftAgent.PromptBuilder prompt: () throws -> SwiftAgent.Prompt
  ) async throws -> Response<String> {
    try await simulateResponse(to: prompt().formatted(), steps: steps)
  }

  @discardableResult
  func simulateResponse<Content>(
    steps: [SimulationStep<Content>],
    @SwiftAgent.PromptBuilder prompt: () throws -> SwiftAgent.Prompt
  ) async throws -> Response<Content> where Content: MockableGenerable {
    try await simulateResponse(to: prompt().formatted(), steps: steps)
  }
}
