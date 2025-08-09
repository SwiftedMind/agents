// By Dennis Müller

import Core
import Engines
import Foundation
import FoundationModels

@Observable @MainActor
public final class SwiftAgent {
  public var transcript: Core.Transcript
  private let provider: any Engine

  public init(
    using provider: Provider,
    tools: [any SwiftAgentTool] = [],
    instructions: String = ""
  ) {
    self.provider = provider.provider.init(tools: tools, instructions: instructions)
    transcript = .init()
  }

  @discardableResult
  public func respond(
    to content: String,
    options: Core.GenerationOptions = Core.GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: content, responseFormat: nil)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = provider.respond(to: prompt, transcript: transcript)

    var responseContent = ""
    var generatedTranscriptEntities: [Core.Transcript.Entry] = []

    for try await entry in stream {
      transcript.entries.append(entry)
      generatedTranscriptEntities.append(entry)
      if case let .response(response) = entry {
        for segment in response.segments {
          if case let .text(textSegment) = segment {
            responseContent += "\n\n" + textSegment.content
          }
        }
      }
    }

    return Response<String>(
      content: responseContent,
      transcriptEntries: generatedTranscriptEntities
    )
  }

  @discardableResult
  public func respond(
    options: Core.GenerationOptions = Core.GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
  ) -> Response<String> {
    Response<String>(
      content: "",
      transcriptEntries: []
    )
  }
}

public extension SwiftAgent {  
  struct Response<Content> where Content: Generable {
    /// The response content.
    public var content: Content

    /// The list of transcript entries.
    public var transcriptEntries: [Core.Transcript.Entry]
  }
}

// MARK: - Helpers

private extension Provider {
  var provider: any Engine.Type {
    switch self {
    case .openAI:
      return OpenAIEngine.self
    }
  }
}
