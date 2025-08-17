// By Dennis Müller

import Foundation
import FoundationModels
import Internal
import OpenAI
import OSLog

public final class OpenAIAdapter: AgentAdapter {
  public typealias Model = OpenAI.Model
  public typealias Transcript<Context: PromptContext> = AgentTranscript<Metadata, Context>

  private var tools: [any AgentTool]
  private var instructions: String = ""
  private let httpClient: HTTPClient
  private let responsesPath: String

  // MARK: - Metadata

  public struct Metadata: AdapterMetadata {
    public typealias Reasoning = ReasoningMetadata
    public typealias Response = OutputMessageMetadata
  }

  public struct ReasoningMetadata: Codable, Sendable, Equatable {
    public var reasoningId: String

    package init(reasoningId: String) {
      self.reasoningId = reasoningId
    }
  }

  public struct OutputMessageMetadata: Codable, Sendable, Equatable {
    public var messageOutputId: String

    package init(messageOutputId: String) {
      self.messageOutputId = messageOutputId
    }
  }

  // MARK: - Configuration

  public struct Configuration: AdapterConfiguration {
    public var httpClient: HTTPClient
    public var responsesPath: String

    public init(httpClient: HTTPClient, responsesPath: String = "/v1/responses") {
      self.httpClient = httpClient
      self.responsesPath = responsesPath
    }

    /// Default configuration used by the protocol-mandated initializer.
    /// To customize, use the initializer that accepts a `Configuration`, or `Configuration.direct(...)`.
    public static var `default`: Configuration = {
      let baseURL = URL(string: "https://api.openai.com")!
      let config = HTTPClientConfiguration(
        baseURL: baseURL,
        defaultHeaders: [:],
        timeout: 60,
        jsonEncoder: JSONEncoder(),
        jsonDecoder: JSONDecoder(),
        interceptors: .init()
      )
      return Configuration(httpClient: URLSessionHTTPClient(configuration: config))
    }()

    /// Convenience builder for calling OpenAI directly with an API key.
    /// Users can alternatively point `baseURL` to their own backend and omit the apiKey.
    public static func direct(
      apiKey: String,
      baseURL: URL = URL(string: "https://api.openai.com")!,
      responsesPath: String = "/v1/responses"
    ) -> Configuration {
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      // Keep defaults; OpenAI models define their own coding keys

      let interceptors = HTTPClientInterceptors(
        prepareRequest: { request in
          request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        },
        onUnauthorized: { _, _, _ in
          // Let the caller decide how to refresh; default is not to retry
          false
        }
      )

      let config = HTTPClientConfiguration(
        baseURL: baseURL,
        defaultHeaders: [:],
        timeout: 60,
        jsonEncoder: encoder,
        jsonDecoder: decoder,
        interceptors: interceptors
      )

      return Configuration(httpClient: URLSessionHTTPClient(configuration: config), responsesPath: responsesPath)
    }
  }

  public init(
    tools: [any AgentTool],
    instructions: String,
    configuration: Configuration
  ) {
    self.tools = tools
    self.instructions = instructions
    httpClient = configuration.httpClient
    responsesPath = configuration.responsesPath
  }

  public func respond<Content, Context>(
    to prompt: Transcript<Context>.Prompt,
    generating type: Content.Type,
    using model: Model = .default,
    including transcript: Transcript<Context>,
    options: GenerationOptions
  ) -> AsyncThrowingStream<Transcript<Context>.Entry, any Error> where Content: Generable, Context: PromptContext {
    let setup = AsyncThrowingStream<Transcript<Context>.Entry, any Error>.makeStream()

    // Log start of an agent run
    AgentLog.start(
      model: String(describing: model),
      toolNames: tools.map(\.name),
      promptPreview: prompt.content
    )

    let task = Task<Void, Never> {
      do {
        try await run(transcript: transcript, generating: type, using: model, options: options, continuation: setup.continuation)
      } catch {
        // Surface a clear, user-friendly message
        AgentLog.error(error, context: "respond")
        setup.continuation.finish(throwing: error)
      }

      setup.continuation.finish()
    }

    setup.continuation.onTermination = { _ in
      task.cancel()
    }

    return setup.stream
  }

  private func run<Content, Context>(
    transcript: Transcript<Context>,
    generating type: Content.Type,
    using model: Model = .default,
    options: GenerationOptions,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: Generable, Context: PromptContext {
    var generatedTranscript = Transcript<Context>()
    let allowedSteps = 20
    var currentStep = 0

    for _ in 0..<allowedSteps {
      currentStep += 1

      AgentLog.stepRequest(step: currentStep)

      let request = request(
        including: Transcript<Context>(entries: transcript.entries + generatedTranscript.entries),
        generating: type,
        using: model,
        options: options
      )

      try Task.checkCancellation()

      // Call provider backend
      let response = try await httpClient.send(
        path: responsesPath,
        method: .post,
        queryItems: nil,
        headers: nil,
        body: request,
        responseType: OpenAI.Response.self
      )

      for output in response.output {
        try await handleOutput(
          output,
          type: type,
          generatedTranscript: &generatedTranscript,
          continuation: continuation
        )
      }

      let outputFunctionCalls = response.output.compactMap { output -> Item.FunctionCall? in
        guard case let .functionCall(functionCall) = output else { return nil }

        return functionCall
      }

      if outputFunctionCalls.isEmpty {
        AgentLog.finish()
        continuation.finish()
        return
      }
    }
  }

  private func handleOutput<Content, Context>(
    _ output: Item.Output,
    type: Content.Type,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: Generable, Context: PromptContext {
    switch output {
    case let .message(message):
      try await handleMessage(
        message,
        type: type,
        generatedTranscript: &generatedTranscript,
        continuation: continuation
      )
    case let .functionCall(functionCall):
      try await handleFunctionCall(
        functionCall,
        generatedTranscript: &generatedTranscript,
        continuation: continuation
      )
    case let .reasoning(reasoning):
      try await handleReasoning(
        reasoning,
        generatedTranscript: &generatedTranscript,
        continuation: continuation
      )
    default:
      Logger.main.warning("Unsupported output received: \(String(describing: output), privacy: .public)")
    }
  }

  private func handleMessage<Content, Context>(
    _ message: Message.Output,
    type: Content.Type,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: Generable, Context: PromptContext {
    if type == String.self {
      try await processStringResponse(
        message,
        generatedTranscript: &generatedTranscript,
        continuation: continuation
      )
    } else {
      try await processStructuredResponse(
        message,
        type: type,
        generatedTranscript: &generatedTranscript,
        continuation: continuation
      )
    }
  }

  private func processStringResponse<Context>(
    _ message: Message.Output,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContext {
    let response = Transcript<Context>.Response(
      segments: message.content.compactMap(\.asText).map { .text(Transcript.TextSegment(content: $0)) },
      status: transcriptStatusFromOpenAIStatus(message.status),
      metadata: Metadata.Response(messageOutputId: message.id)
    )

    let text = message.content.compactMap(\.asText).joined(separator: "\n")
    AgentLog.outputMessage(text: text, status: String(describing: message.status))

    generatedTranscript.entries.append(.response(response))
    continuation.yield(.response(response))
  }

  private func processStructuredResponse<Content, Context>(
    _ message: Message.Output,
    type: Content.Type,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Content: Generable, Context: PromptContext {
    guard let content = message.content.first else {
      let errorContext = GenerationError.EmptyMessageContentContext(expectedType: String(describing: type))
      throw GenerationError.emptyMessageContent(errorContext)
    }

    switch content {
    case let .text(text, _, _):
      do {
        let generatedContent = try GeneratedContent(json: text)
        let response = Transcript<Context>.Response(
          segments: [.structure(Transcript.StructuredSegment(content: generatedContent))],
          status: transcriptStatusFromOpenAIStatus(message.status),
          metadata: Metadata.Response(messageOutputId: message.id)
        )

        AgentLog.outputStructured(json: text, status: String(describing: message.status))

        generatedTranscript.entries.append(.response(response))
        continuation.yield(.response(response))
      } catch {
        AgentLog.error(error, context: "structured_response_parsing")
        let errorContext = GenerationError.StructuredContentParsingFailedContext(
          rawContent: text,
          underlyingError: error
        )
        throw GenerationError.structuredContentParsingFailed(errorContext)
      }
    case .refusal:
      let errorContext = GenerationError.ContentRefusalContext(expectedType: String(describing: type))
      throw GenerationError.contentRefusal(errorContext)
    }
  }

  private func handleFunctionCall<Context>(
    _ functionCall: Item.FunctionCall,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContext {
    let generatedContent = try GeneratedContent(json: functionCall.arguments)

    let toolCall = Transcript<Context>.ToolCall(
      callId: functionCall.callId,
      toolName: functionCall.name,
      arguments: generatedContent,
      status: transcriptStatusFromOpenAIStatus(functionCall.status)
    )

    AgentLog.toolCall(
      name: functionCall.name,
      callId: functionCall.callId,
      argumentsJSON: functionCall.arguments
    )

    generatedTranscript.entries.append(.toolCalls(Transcript.ToolCalls(calls: [toolCall])))
    continuation.yield(.toolCalls(Transcript.ToolCalls(calls: [toolCall])))

    guard let tool = tools.first(where: { $0.name == functionCall.name }) else {
      AgentLog.error(GenerationError.unsupportedToolCalled(.init(toolName: functionCall.name)), context: "tool_not_found")
      let errorContext = GenerationError.UnsupportedToolCalledContext(toolName: functionCall.name)
      throw GenerationError.unsupportedToolCalled(errorContext)
    }

    do {
      let output = try await callTool(tool, with: generatedContent)

      let toolOutputEntry = Transcript<Context>.ToolOutput.generatedContent(
        output,
        callId: functionCall.callId,
        toolName: tool.name
      )
      let transcriptEntry = Transcript<Context>.Entry.toolOutput(toolOutputEntry)

      // Try to log as JSON if possible
      AgentLog.toolOutput(
        name: tool.name,
        callId: functionCall.callId,
        outputJSONOrText: output.generatedContent.jsonString
      )

      generatedTranscript.entries.append(transcriptEntry)
      continuation.yield(transcriptEntry)
    } catch {
      AgentLog.error(error, context: "tool_call_failed_\(tool.name)")
      throw ToolCallError(tool: tool, underlyingError: error)
    }
  }

  private func handleReasoning<Context>(
    _ reasoning: Item.Reasoning,
    generatedTranscript: inout Transcript<Context>,
    continuation: AsyncThrowingStream<Transcript<Context>.Entry, any Error>.Continuation
  ) async throws where Context: PromptContext {
    // TODO: Always empty for some reason
    let summary = reasoning.summary.map { summary in
      switch summary {
      case let .text(text):
        return text
      }
    }

    let entryData = Transcript<Context>.Reasoning(
      summary: summary,
      encryptedReasoning: reasoning.encryptedContent,
      status: transcriptStatusFromOpenAIStatus(reasoning.status),
      metadata: ReasoningMetadata(reasoningId: reasoning.id)
    )

    AgentLog.reasoning(summary: summary)

    let entry = Transcript<Context>.Entry.reasoning(entryData)
    generatedTranscript.entries.append(entry)
    continuation.yield(entry)
  }

  private func callTool<T: FoundationModels.Tool>(
    _ tool: T,
    with generatedContent: GeneratedContent
  ) async throws -> T.Output where T.Output: ConvertibleToGeneratedContent {
    let arguments = try T.Arguments(generatedContent)
    return try await tool.call(arguments: arguments)
  }

  private func request<Content, Context>(
    including transcript: Transcript<Context>,
    generating type: Content.Type,
    using model: Model,
    options: GenerationOptions
  ) -> OpenAI.Request where Content: Generable, Context: PromptContext {
    let textConfig: TextConfig? = {
      if type == String.self {
        return nil
      }

      let format = TextConfig.Format.generationSchema(
        schema: type.generationSchema,
        name: snakeCaseName(for: type),
        strict: false
      )

      return TextConfig(format: format)
    }()

    return Request(
      model: model,
      input: .list(transcriptToListItems(transcript)),
      include: model.isReasoning ? [.encryptedReasoning] : nil,
      instructions: instructions,
      maxOutputTokens: options.maximumResponseTokens,
      reasoning: ReasoningConfig(effort: .low, summary: .detailed),
      safetyIdentifier: "",
      store: false,
      temperature: model.isReasoning ? nil : options.temperature,
      text: textConfig,
      tools: tools.map { tool in
        .function(
          name: tool.name,
          description: tool.description,
          parameters: tool.parameters,
          strict: false // Important because GenerationSchema doesn't produce a compliant strict schema for OpenAI!
        )
      }
    )
  }

  // MARK: - Helpers

  private func transcriptStatusFromOpenAIStatus<Context>(
    _ status: Message.Status
  ) -> Transcript<Context>.Status where Context: PromptContext {
    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  private func transcriptStatusFromOpenAIStatus<Context>(
    _ status: Item.FunctionCall.Status
  ) -> Transcript<Context>.Status where Context: PromptContext {
    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  private func transcriptStatusFromOpenAIStatus<Context>(
    _ status: Item.Reasoning.Status?
  ) -> Transcript<Context>.Status? where Context: PromptContext {
    guard let status else { return nil }

    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  private func transcriptStatusToMessageStatus<Context>(
    _ status: Transcript<Context>.Status
  ) -> Message.Status where Context: PromptContext {
    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  private func transcriptStatusToFunctionCallStatus<Context>(
    _ status: Transcript<Context>.Status
  ) -> Item.FunctionCall.Status where Context: PromptContext {
    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  private func transcriptStatusToReasoningStatus<Context>(
    _ status: Transcript<Context>.Status?
  ) -> Item.Reasoning.Status? where Context: PromptContext {
    guard let status else { return nil }

    switch status {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  func transcriptToListItems<Context>(_ transcript: Transcript<Context>) -> [Input.ListItem] where Context: PromptContext {
    var listItems: [Input.ListItem] = []

    for entry in transcript.entries {
      switch entry {
      case let .prompt(prompt):
        listItems.append(Input.ListItem.message(role: .user, content: .text(prompt.embeddedPrompt)))
      case let .reasoning(reasoning):
        let item = Item.Reasoning(
          id: reasoning.metadata.reasoningId,
          summary: [],
          status: transcriptStatusToReasoningStatus(reasoning.status),
          encryptedContent: reasoning.encryptedReasoning
        )

        listItems.append(Input.ListItem.item(.reasoning(item)))
      case let .toolCalls(toolCalls):
        for toolCall in toolCalls.calls {
          let item = Item.FunctionCall(
            arguments: toolCall.arguments.jsonString,
            callId: toolCall.callId,
            id: "fc_" + toolCall.id,
            name: toolCall.toolName,
            status: transcriptStatusToFunctionCallStatus(toolCall.status)
          )

          listItems.append(Input.ListItem.item(.functionCall(item)))
        }
      case let .toolOutput(toolOutput):
        let output: String = {
          switch toolOutput.segment {
          case let .text(textSegment):
            return textSegment.content
          case let .structure(structuredSegment):
            return structuredSegment.content.generatedContent.jsonString
          }
        }()

        let item = Item.FunctionCallOutput(
          id: "fc_" + toolOutput.id,
          status: nil,
          callId: toolOutput.callId,
          output: output
        )

        listItems.append(Input.ListItem.item(.functionCallOutput(item)))
      case let .response(response):
        let item = Message.Output(
          content: response.segments.compactMap { segment in
            switch segment {
            case let .text(textSegment):
              return Item.Output.Content.text(text: textSegment.content, annotations: [], logprobs: [])
            case .structure:
              // Not supported right now
              return nil
            }
          },
          id: response.metadata.messageOutputId,
          role: .assistant,
          status: transcriptStatusToMessageStatus(response.status)
        )

        listItems.append(Input.ListItem.item(.outputMessage(item)))
      }
    }

    return listItems
  }
}

// MARK: - Helpers

func snakeCaseName<T>(for type: T.Type) -> String {
  let name = String(describing: type)
    .replacingOccurrences(of: ".Type", with: "")

  return name.reduce(into: "") { result, char in
    if char.isUppercase, !result.isEmpty {
      result.append("_")
    }
    result.append(char.lowercased())
  }
}

extension OpenAI.Model: AdapterModel {
  public static var `default`: Self {
    .gpt5
  }

  public var isReasoning: Bool {
    switch self {
    case .gpt5,
         .gpt5_mini,
         .gpt5_nano,
         .o1,
         .o1Pro,
         .o1Mini,
         .o3,
         .o3Pro,
         .o3Mini,
         .o4Mini,
         .o4MiniDeepResearch:
      return true
    default: return false
    }
  }
}
