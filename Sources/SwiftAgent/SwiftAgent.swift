// By Dennis Müller

@_exported import Core
import Foundation
import FoundationModels

@Observable @MainActor
public final class SwiftAgent {
  public var transcript: Core.Transcript
  private let provider: any Engine

  public init(
    using provider: EngineProvider,
    tools: [any SwiftAgentTool] = [],
    instructions: String = ""
  ) {
    transcript = Core.Transcript()
    switch provider {
    case let .openAI(configuration):
      self.provider = OpenAIEngine(tools: tools, instructions: instructions, configuration: configuration)
    }
  }

  @discardableResult
  public func respond(
    to content: String,
    options: Core.GenerationOptions = Core.GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: content, responseFormat: nil)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = provider.respond(to: prompt, generating: String.self, including: transcript)
    var responseContent = ""
    var addedEntities: [Core.Transcript.Entry] = []

    for try await entry in stream {
      transcript.entries.append(entry)
      addedEntities.append(entry)

      if case let .response(response) = entry {
        for segment in response.segments {
          switch segment {
          case let .text(textSegment):
            responseContent += "\n\n" + textSegment.content
          case .structure:
            // Not applicable here
            break
          }
        }
      }
    }

    return Response<String>(
      content: responseContent,
      addedEntries: addedEntities
    )
  }

  @discardableResult
  public func respond<Content>(
    to content: String,
    generating type: Content.Type = Content.self,
    options: Core.GenerationOptions = Core.GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(content: content, responseFormat: nil)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = provider.respond(to: prompt, generating: type, including: transcript)
    var addedEntities: [Core.Transcript.Entry] = []

    for try await entry in stream {
      transcript.entries.append(entry)
      addedEntities.append(entry)

      if case let .response(response) = entry {
        for segment in response.segments {
          switch segment {
          case let .text(textSegment):
            // Not applicable here
            break
          case let .structure(structuredSegment):
            // We can return here since a structured response can only happen once
            // TODO: Handle errors here in some way
            return try Response<Content>(
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
}

public extension SwiftAgent {
  struct Response<Content> where Content: Generable {
    /// The response content.
    public var content: Content

    /// The transcript entries that the prompt produced.
    public var addedEntries: [Core.Transcript.Entry]
  }
}
