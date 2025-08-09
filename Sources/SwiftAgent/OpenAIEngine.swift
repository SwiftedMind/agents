// By Dennis Müller

import Core
import Foundation
import FoundationModels
import OpenAI
import SwiftAgentNetworking

public final class OpenAIEngine: Engine {
  private var tools: [any SwiftAgentTool]
  private var instructions: String = ""
  private let httpClient: HTTPClient
  private let responsesPath: String

  // MARK: - Configuration

  public struct Configuration: Core.EngineConfiguration {
    public var httpClient: HTTPClient
    public var responsesPath: String

    public init(httpClient: HTTPClient, responsesPath: String = "/v1/responses") {
      self.httpClient = httpClient
      self.responsesPath = responsesPath
    }

    /// Default configuration used by the protocol-mandated initializer.
    /// To customize, use the initializer that accepts a `Configuration`, or `Configuration.openAIDirect(...)`.
    public internal(set) static var defaultConfiguration: Configuration = {
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

    /// Overrides the static default configuration used by convenience providers.
    public static func setDefaultConfiguration(_ configuration: Configuration) {
      Self.defaultConfiguration = configuration
    }

    /// Convenience builder for calling OpenAI directly with an API key.
    /// Users can alternatively point `baseURL` to their own backend and omit the apiKey.
    public static func openAIDirect(apiKey: String, baseURL: URL = URL(string: "https://api.openai.com")!, responsesPath: String = "/v1/responses") -> Configuration {
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
    tools: [any SwiftAgentTool],
    instructions: String,
    configuration: Configuration
  ) {
    self.tools = tools
    self.instructions = instructions
    httpClient = configuration.httpClient
    responsesPath = configuration.responsesPath
  }

  public func respond<Content>(
    to prompt: Core.Transcript.Prompt,
    generating type: Content.Type,
    including transcript: Core.Transcript
  ) -> AsyncThrowingStream<Core.Transcript.Entry, any Error> where Content: Generable {
    print("RESPOND. Transcript: \(transcript)")
    let setup = AsyncThrowingStream<Core.Transcript.Entry, any Error>.makeStream()

    let task = Task<Void, Never> {
      do {
        try await run(transcript: transcript, generating: type, continuation: setup.continuation)
      } catch {
        setup.continuation.finish(throwing: error)
      }

      setup.continuation.finish()
    }

    setup.continuation.onTermination = { _ in
      task.cancel()
    }

    return setup.stream
  }

  private func run<Content>(
    transcript: Core.Transcript,
    generating type: Content.Type,
    continuation: AsyncThrowingStream<Core.Transcript.Entry, any Error>.Continuation
  ) async throws where Content: Generable {
    var generatedTranscript = Core.Transcript()
    let allowedSteps = 10
    var currentStep = 0

    for _ in 0..<allowedSteps {
      currentStep += 1

      let request = request(
        including: Core.Transcript(entries: transcript.entries + generatedTranscript.entries),
        generating: type
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
        print("Step \(currentStep): Output: \(output), generated transcript: \(generatedTranscript)")

        switch output {
        case let .message(message):
          print("Message: \(message)")

          let response = Core.Transcript.Response(
            segments: [.text(Core.Transcript.TextSegment(content: message.text))],
            status: message.status.asTranscriptStatus
          )

          generatedTranscript.entries.append(.response(response))
          continuation.yield(.response(response))
        case let .functionCall(functionCall):
          print("Function Call: \(functionCall)")

          // Parse the arguments
          let generatedContent = try GeneratedContent(json: functionCall.arguments)

          let toolCall = Core.Transcript.ToolCall(
            callId: functionCall.callId,
            toolName: functionCall.name,
            arguments: generatedContent,
            status: functionCall.status.asTranscriptStatus
          )

          // Update the generated transcript and yield
          generatedTranscript.entries.append(.toolCalls(Core.Transcript.ToolCalls(calls: [toolCall])))
          continuation.yield(.toolCalls(Core.Transcript.ToolCalls(calls: [toolCall])))

          if let tool = tools.first(where: { $0.name == functionCall.name }) {
            do {
              // Call the tool and return its output
              let output = try await callTool(tool, with: generatedContent)

              print("Output: \(output.generatedContent.jsonString)")

              // Prepare the output transcript entry
              let toolOutputEntry = Core.Transcript.ToolOutput.generatedContent(
                output,
                callId: functionCall.callId,
                toolName: tool.name
              )
              let transcriptEntry = Core.Transcript.Entry.toolOutput(toolOutputEntry)

              // Yield the output to the transcript
              generatedTranscript.entries.append(transcriptEntry)
              continuation.yield(transcriptEntry)
            } catch {
              continuation.finish(throwing: ToolCallError(tool: tool, underlyingError: error))
            }
          } else {
            let errorContext = GenerationError.UnsupportedToolCalledContext(toolName: functionCall.name)
            continuation.finish(throwing: GenerationError.unsupportedToolCalled(errorContext))
          }
        case let .reasoning(reasoning):
          print("RECEIVED REASONING: \(reasoning)")

          let summary = reasoning.summary.map { summary in
            switch summary {
            case let .text(text):
              return text
            }
          }

          let entryData = Core.Transcript.Reasoning(
            summary: summary,
            status: reasoning.status?.asTranscriptStatus
          )

          let entry = Transcript.Entry.reasoning(entryData)
        default:
          print("Warning: Unsupported output received: \(output)")
//          AppLogger.assistant.warning("Unsupported output received: \(output.jsonString())")
        }

        let outputFunctionCalls = response.output.compactMap { output -> Item.FunctionCall? in
          guard case let .functionCall(functionCall) = output else { return nil }

          return functionCall
        }

        if outputFunctionCalls.isEmpty {
          print("ENDED")
          continuation.finish()
          return
        }
      }

      // TODO: Implement tool call handling and state updates for store
    }
  }

  private func callTool<T: FoundationModels.Tool>(
    _ tool: T,
    with generatedContent: GeneratedContent
  ) async throws -> T.Output where T.Output: ConvertibleToGeneratedContent {
    let arguments = try T.Arguments(generatedContent)
    return try await tool.call(arguments: arguments)
  }

  private func request<Content>(
    including transcript: Core.Transcript,
    generating type: Content.Type,
  ) -> OpenAI.Request where Content: Generable {
    let textConfig: TextConfig? = {
      if type == String.self {
        return nil
      }
      let format = TextConfig.Format.generationSchema(
        schema: type.generationSchema,
        description: "",
        name: "",
        strict: false
      )
      return TextConfig(format: format)
    }()
    
    return Request(
      model: .other("gpt-5"),
      input: .list(transcript.asOpenAIListItems()),
      instructions: instructions,
      safetyIdentifier: "",
      store: true,
//      temperature: 0.0, // Not supported by gpt-5
      text: textConfig,
      tools: tools.map { .function(name: $0.name, description: $0.description, parameters: $0.parameters) }
    )
  }
}

private extension Core.Transcript {
  func asOpenAIListItems() -> [Input.ListItem] {
    var listItems: [Input.ListItem] = []

    for entry in entries {
      switch entry {
      case let .prompt(prompt):
        listItems.append(
          Input.ListItem.message(role: .user, content: .text(prompt.content))
        )
      case let .reasoning(reasoning):
        let item = Item.Reasoning(
          id: reasoning.id,
          summary: reasoning.summary.map { .text($0) },
          status: reasoning.status?.asReasoningStatus,
          encryptedContent: nil
        )

        listItems.append(Input.ListItem.item(.reasoning(item)))
      case let .toolCalls(toolCalls):
        for toolCall in toolCalls.calls {
          let item = Item.FunctionCall(
            arguments: toolCall.arguments.jsonString,
            callId: toolCall.callId,
            id: "fc_" + toolCall.id,
            name: toolCall.toolName,
            status: toolCall.status.asFunctionCallStatus
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
          id: response.id,
          role: .assistant,
          status: response.status.asOpenAIStatus
        )

        listItems.append(Input.ListItem.item(.outputMessage(item)))
      }
    }

    return listItems
  }
}

// MARK: - Helpers

extension Core.Transcript.Status {
  var asOpenAIStatus: Message.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  var asFunctionCallStatus: Item.FunctionCall.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }

  var asReasoningStatus: Item.Reasoning.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }
}

extension Message.Status {
  var asTranscriptStatus: Core.Transcript.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }
}

extension Item.FunctionCall.Status {
  var asTranscriptStatus: Core.Transcript.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }
}

extension Item.Reasoning.Status {
  var asTranscriptStatus: Core.Transcript.Status {
    switch self {
    case .completed: return .completed
    case .incomplete: return .incomplete
    case .inProgress: return .inProgress
    }
  }
}
