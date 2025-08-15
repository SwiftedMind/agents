// By Dennis Müller

@_exported import Core
import Foundation
import FoundationModels

@Observable @MainActor
public final class Agent<P: Provider> {
  public typealias Prompt = Core.Prompt
  public typealias PromptRepresentable = Core.PromptRepresentable
  public typealias PromptBuilder = Core.PromptBuilder
  public typealias Transcript = Core.Transcript<P.Metadata>
  public typealias GenerationOptions = Core.GenerationOptions
  public typealias Response<Content: Generable> = AgentResponse<P, Content>

  private let provider: P

  public var transcript: Transcript

  public init(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: P.Configuration = .default
  ) {
    transcript = Transcript()
    provider = P(tools: tools, instructions: instructions, configuration: configuration)
  }

  @discardableResult
  public func respond(
    to content: String,
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: content, responseFormat: nil)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = provider.respond(to: prompt, generating: String.self, using: model, including: transcript, options: options)
    var responseContent = ""
    var addedEntities: [Transcript.Entry] = []

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

    return AgentResponse<P, String>(content: responseContent, addedEntries: addedEntities)
  }

  @discardableResult
  public func respond(
    to prompt: Prompt,
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<String> {
    try await respond(to: prompt.formatted(), using: model, options: options)
  }

  @discardableResult
  public func respond(
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
  ) async throws -> Response<String> {
    try await respond(to: prompt().formatted(), using: model, options: options)
  }

  @discardableResult
  public func respond<Content>(
    to content: String,
    generating type: Content.Type = Content.self,
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(content: content, responseFormat: nil)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = provider.respond(to: prompt, generating: type, using: model, including: transcript, options: options)
    var addedEntities: [Transcript.Entry] = []

    for try await entry in stream {
      transcript.entries.append(entry)
      addedEntities.append(entry)

      if case let .response(response) = entry {
        for segment in response.segments {
          switch segment {
          case .text:
            // Not applicable here
            break
          case let .structure(structuredSegment):
            // We can return here since a structured response can only happen once
            // TODO: Handle errors here in some way
            return try AgentResponse<P, Content>(
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
  public func respond<Content>(
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    try await respond(
      to: prompt.formatted(),
      generating: type,
      using: model,
      options: options
    )
  }

  @discardableResult
  public func respond<Content>(
    generating type: Content.Type = Content.self,
    using model: P.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
  ) async throws -> Response<Content> where Content: Generable {
    try await respond(
      to: prompt().formatted(),
      generating: type,
      using: model,
      options: options
    )
  }
}

public struct AgentResponse<P: Provider, Content> where Content: Generable {
  /// The response content.
  public var content: Content

  /// The transcript entries that the prompt produced.
  public var addedEntries: [Agent<P>.Transcript.Entry]
}
