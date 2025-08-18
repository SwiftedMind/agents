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

  /// Shared initialization logic used by all public initializers
  init(adapter: Adapter) {
    transcript = Transcript()
    self.adapter = adapter
  }

  // MARK: - Private Response Helpers

  /// Processes a stream response for String content
  private func processStringResponse(
    from prompt: Transcript.Prompt,
    using model: Adapter.Model,
    options: Adapter.GenerationOptions
  ) async throws -> Response<String> {
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.append(promptEntry)

    let stream = adapter.respond(
      to: prompt,
      generating: String.self,
      using: model,
      including: transcript,
      options: options
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
            // Not applicable here
            break
          }
        }
      }
    }

    return AgentResponse<Adapter, Context, String>(
      content: responseContent.joined(separator: "\n"),
      addedEntries: addedEntities
    )
  }

  /// Processes a stream response for structured content
  private func processStructuredResponse<Content>(
    from prompt: Transcript.Prompt,
    generating type: Content.Type,
    using model: Adapter.Model,
    options: Adapter.GenerationOptions
  ) async throws -> Response<Content> where Content: Generable {
    let promptEntry = Transcript.Entry.prompt(prompt)
    transcript.append(promptEntry)

    let stream = adapter.respond(
      to: prompt,
      generating: type,
      using: model,
      including: transcript,
      options: options
    )
    var addedEntities: [Transcript.Entry] = []

    for try await entry in stream {
      transcript.append(entry)
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

// MARK: - Agent + Initializers

public extension Agent {
  // MARK: Generic Initializers

  convenience init(
    using adapter: Adapter.Type,
    supplying context: Context.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) {
    self.init(adapter: Adapter(tools: tools, instructions: instructions, configuration: configuration))
  }

  convenience init(
    using adapter: Adapter.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Context == EmptyPromptContext {
    self.init(adapter: Adapter(tools: tools, instructions: instructions, configuration: configuration))
  }

  // MARK: OpenAI Initializers

  convenience init(
    supplying context: Context.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Adapter == OpenAIAdapter {
    self.init(adapter: Adapter(tools: tools, instructions: instructions, configuration: configuration))
  }

  convenience init(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Adapter == OpenAIAdapter, Context == EmptyPromptContext {
    self.init(adapter: Adapter(tools: tools, instructions: instructions, configuration: configuration))
  }
}

// MARK: - Agent + String Responses

public extension Agent {
  @discardableResult
  func respond(
    to prompt: String,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions()
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: prompt)
    return try await processStringResponse(from: prompt, using: model, options: options)
  }

  @discardableResult
  func respond(
    to prompt: Prompt,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions()
  ) async throws -> Response<String> {
    try await respond(to: prompt.formatted(), using: model, options: options)
  }

  @discardableResult
  func respond(
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
  ) async throws -> Response<String> {
    try await respond(to: prompt().formatted(), using: model, options: options)
  }
}

// MARK: - Agent + Generic Responses

public extension Agent {
  @discardableResult
  func respond<Content>(
    to prompt: String,
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(content: prompt, embeddedPrompt: prompt)
    return try await processStructuredResponse(from: prompt, generating: type, using: model, options: options)
  }

  @discardableResult
  func respond<Content>(
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions()
  ) async throws -> Response<Content> where Content: Generable {
    try await respond(
      to: prompt.formatted(),
      generating: type,
      using: model,
      options: options
    )
  }

  @discardableResult
  func respond<Content>(
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
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

// MARK: - Agent + Context Responses

public extension Agent {
  @discardableResult
  func respond(
    to input: String,
    supplying context: [Context],
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ input: String, _ context: [Context]) -> Prompt
  ) async throws -> Response<String> {
    let prompt = Transcript.Prompt(
      content: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )
    return try await processStringResponse(from: prompt, using: model, options: options)
  }

  @discardableResult
  func respond<Content>(
    to input: String,
    supplying context: [Context],
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ prompt: String, _ embeddables: [Context]) -> Prompt
  ) async throws -> Response<Content> where Content: Generable {
    let prompt = Transcript.Prompt(
      content: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )
    return try await processStructuredResponse(from: prompt, generating: type, using: model, options: options)
  }
}

// MARK: - AgentResponse

public struct AgentResponse<Adapter: AgentAdapter, Context: PromptContext, Content> where Content: Generable {
  /// The response content.
  public var content: Content

  /// The transcript entries that the prompt produced.
  public var addedEntries: [Agent<Adapter, Context>.Transcript.Entry]
}
