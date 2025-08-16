// By Dennis Müller

@_exported import Core
import Foundation
import FoundationModels

// TODO: Take some time and rethink the naming of everything. Feels super wacky right now

@Observable @MainActor
public final class Agent<Adapter: AgentAdapter, Embeddable: PromptEmbeddable> {
  public typealias Transcript = SwiftAgent.Transcript<Adapter.Metadata, Embeddable>
  public typealias Response<Content: Generable> = AgentResponse<Adapter, Embeddable, Content>

  private let provider: Adapter

  public var transcript: Transcript

  public init(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) {
    transcript = Transcript()
    provider = Adapter(tools: tools, instructions: instructions, configuration: configuration)
  }

  @discardableResult
  public func respond(
    to prompt: String,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: prompt)
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

    return AgentResponse<Adapter, Embeddable, String>(content: responseContent, addedEntries: addedEntities)
  }

  @discardableResult
  public func respond(
    to prompt: Prompt,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<String> {
    try await respond(to: prompt.formatted(), using: model, options: options)
  }

  @discardableResult
  public func respond(
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
  ) async throws -> Response<String> {
    try await respond(to: prompt().formatted(), using: model, options: options)
  }

  @discardableResult
  public func respond<Content>(
    to prompt: String,
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: prompt)
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
            return try AgentResponse<Adapter, Embeddable, Content>(
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
    using model: Adapter.Model = .default,
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
    using model: Adapter.Model = .default,
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

  // MARK: - Embeddings

  @discardableResult
  public func respond(
    to prompt: String,
    with embeds: [Embeddable],
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder embedding: @Sendable (_ prompt: String, _ embeds: [Embeddable]) -> Prompt
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: embedding(prompt, embeds).formatted())
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

    return AgentResponse<Adapter, Embeddable, String>(content: responseContent, addedEntries: addedEntities)
  }

  @discardableResult
  public func respond<Content>(
    to prompt: String,
    with embeds: [Embeddable],
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder embedding: @Sendable (_ prompt: String, _ embeds: [Embeddable]) -> Prompt
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(content: prompt, embeds: embeds, embeddedPrompt: embedding(prompt, embeds).formatted())

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
            return try AgentResponse<Adapter, Embeddable, Content>(
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

public struct AgentResponse<Adapter: AgentAdapter, Embeddable: PromptEmbeddable, Content> where Content: Generable {
  /// The response content.
  public var content: Content

  /// The transcript entries that the prompt produced.
  public var addedEntries: [Agent<Adapter, Embeddable>.Transcript.Entry]
}
