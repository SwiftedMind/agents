// By Dennis Müller

import Foundation
import FoundationModels

public typealias OpenAIAgent<Context: PromptContext> = Agent<OpenAIAdapter, Context>

@Observable @MainActor
public final class Agent<Adapter: AgentAdapter, Context: PromptContext> {
  public typealias Transcript = AgentTranscript<Adapter.Metadata, Context>
  public typealias Response<Content: Generable> = AgentResponse<Adapter, Context, Content>

  private let adapter: Adapter

  public var transcript: Transcript

  // MARK: - Initializers

  // MARK: Generic Initializers

  public init(
    using adapter: Adapter.Type,
    supplying context: Context.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) {
    transcript = Transcript()
    self.adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
  }

  public init(
    using adapter: Adapter.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Context == EmptyPromptContext {
    transcript = Transcript()
    self.adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
  }

  // MARK: OpenAI Initializers

  public init(
    supplying context: Context.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Adapter == OpenAIAdapter {
    transcript = Transcript()
    adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
  }

  public init(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Adapter == OpenAIAdapter, Context == EmptyPromptContext {
    transcript = Transcript()
    adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
  }

  // MARK: - Respond Methods

  @discardableResult
  public func respond(
    to prompt: String,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: prompt)
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = adapter.respond(to: prompt, generating: String.self, using: model, including: transcript, options: options)
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

    return AgentResponse<Adapter, Context, String>(content: responseContent, addedEntries: addedEntities)
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

    let stream = adapter.respond(to: prompt, generating: type, using: model, including: transcript, options: options)
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
            return try AgentResponse<Adapter, Context, Content>(
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

  // MARK: - Response with Prompt Context

  @discardableResult
  public func respond(
    to input: String,
    supplying context: [Context],
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ input: String, _ context: [Context]) -> Prompt
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(
      content: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )

    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = adapter.respond(to: prompt, generating: String.self, using: model, including: transcript, options: options)
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

    return AgentResponse<Adapter, Context, String>(content: responseContent, addedEntries: addedEntities)
  }

  @discardableResult
  public func respond<Content>(
    to input: String,
    supplying context: [Context],
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ prompt: String, _ embeddables: [Context]) -> Prompt
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(
      content: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )

    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.entries.append(promptEntry)

    let stream = adapter.respond(to: prompt, generating: type, using: model, including: transcript, options: options)
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
            return try AgentResponse<Adapter, Context, Content>(
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

// MARK: - AgentResponse

public struct AgentResponse<Adapter: AgentAdapter, Context: PromptContext, Content> where Content: Generable {
  /// The response content.
  public var content: Content

  /// The transcript entries that the prompt produced.
  public var addedEntries: [Agent<Adapter, Context>.Transcript.Entry]
}
