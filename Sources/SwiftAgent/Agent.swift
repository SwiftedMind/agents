// By Dennis Müller

import Foundation
import FoundationModels

public typealias OpenAIAgent<ContextReference: PromptContextReference> = Agent<OpenAIAdapter, ContextReference>

@Observable @MainActor
public final class Agent<Adapter: AgentAdapter, ContextReference: PromptContextReference> {
  public typealias Transcript = AgentTranscript<Adapter.Metadata, ContextReference>
  public typealias Context = PromptContext<ContextReference>
  public typealias Response<Content: Generable> = AgentResponse<Adapter, ContextReference, Content>

  package let adapter: Adapter

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

    return AgentResponse<Adapter, ContextReference, String>(
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
}

// MARK: - Agent + Initializers

public extension Agent {
  // MARK: Generic Initializers

  convenience init(
    using adapter: Adapter.Type,
    supplying context: ContextReference.Type,
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
  ) where ContextReference == EmptyPromptContextReference {
    self.init(adapter: Adapter(tools: tools, instructions: instructions, configuration: configuration))
  }

  // MARK: OpenAI Initializers

  convenience init(
    supplying context: ContextReference.Type,
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
  ) where Adapter == OpenAIAdapter, ContextReference == EmptyPromptContextReference {
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
    let prompt = Transcript.Prompt(input: prompt, embeddedPrompt: prompt)
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
    let prompt = Transcript.Prompt(input: prompt, embeddedPrompt: prompt)
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
    supplying contextItems: [ContextReference],
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ input: String, _ context: Context) -> Prompt
  ) async throws -> Response<String> {
    
    let context = Context(references: contextItems, linkPreviews: [])
    
    let prompt = Transcript.Prompt(
      input: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )
    return try await processStringResponse(from: prompt, using: model, options: options)
  }

  @discardableResult
  func respond<Content>(
    to input: String,
    supplying contextItems: [ContextReference],
    generating type: Content.Type = Content.self,
    using model: Adapter.Model = .default,
    options: Adapter.GenerationOptions = Adapter.GenerationOptions(),
    @PromptBuilder embeddingInto prompt: @Sendable (_ prompt: String, _ context: Context) -> Prompt
  ) async throws -> Response<Content> where Content: Generable {
    
    let context = Context(references: contextItems, linkPreviews: [])
    
    let prompt = Transcript.Prompt(
      input: input,
      context: context,
      embeddedPrompt: prompt(input, context).formatted()
    )
    return try await processStructuredResponse(from: prompt, generating: type, using: model, options: options)
  }
}

// MARK: - AgentResponse

public struct AgentResponse<Adapter: AgentAdapter, ContextReference: PromptContextReference, Content> where Content: Generable {
  /// The response content.
  public var content: Content

  /// The transcript entries that the prompt produced.
  public var addedEntries: [Agent<Adapter, ContextReference>.Transcript.Entry]
  
  package init(
    content: Content,
    addedEntries: [Agent<Adapter, ContextReference>.Transcript.Entry]
  ) {
    self.content = content
    self.addedEntries = addedEntries
  }
}
