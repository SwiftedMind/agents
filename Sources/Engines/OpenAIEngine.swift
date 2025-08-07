// By Dennis Müller

import Core
import Foundation
import FoundationModels
import OpenAI
import SwiftAgentNetworking

public final class OpenAIEngine: Engine {
  /// Maps Transcript.Entry.ID to an OpenAI ListItem.
  private var store: [String: Input.ListItem] = [:]

  private var tools: [any FoundationModels.Tool]
  private var instructions: String = ""
  private let httpClient: HTTPClient
  private let responsesPath: String

  // MARK: - Configuration

  public struct Configuration: Sendable {
    public var httpClient: HTTPClient
    public var responsesPath: String

    public init(httpClient: HTTPClient, responsesPath: String = "/v1/responses") {
      self.httpClient = httpClient
      self.responsesPath = responsesPath
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
          return false
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

  /// Default configuration used by the protocol-mandated initializer.
  /// To customize, use the initializer that accepts a `Configuration`, or `Configuration.openAIDirect(...)`.
  public static let defaultConfiguration: Configuration = {
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

  public init(
    tools: [any FoundationModels.Tool],
    instructions: String
  ) {
    self.tools = tools
    self.instructions = instructions
    self.httpClient = Self.defaultConfiguration.httpClient
    self.responsesPath = Self.defaultConfiguration.responsesPath
  }

  public init(
    tools: [any FoundationModels.Tool],
    instructions: String,
    configuration: Configuration
  ) {
    self.tools = tools
    self.instructions = instructions
    self.httpClient = configuration.httpClient
    self.responsesPath = configuration.responsesPath
  }

  public func respond(
    to prompt: Core.Transcript.Prompt,
    transcript: Core.Transcript
  ) -> AsyncThrowingStream<Core.Transcript.Entry, any Error> {
    let setup = AsyncThrowingStream<Core.Transcript.Entry, any Error>.makeStream()

    let task = Task<Void, Never> {
      do {
        let generatedTranscript = try await run(transcript: transcript, continuation: setup.continuation)
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

  private func run(
    transcript: Core.Transcript,
    continuation: AsyncThrowingStream<Core.Transcript.Entry, any Error>.Continuation
  ) async throws -> Core.Transcript {
    var generatedTranscript = Core.Transcript()
    let allowedSteps = 10
    var currentStep = 0

    for _ in 0..<allowedSteps {
      currentStep += 1
      
      let request = request(
        transcript: Core.Transcript(entries: transcript.entries + generatedTranscript.entries)
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
        switch output {
        case let .message(message):
          let response = Core.Transcript.Response(segments: [.text(Core.Transcript.TextSegment(content: message.text))])
          
          generatedTranscript.entries.append(.response(response))
          continuation.yield(.response(response))
        case let .functionCall(functionCall):
          // TODO: Implement
          break
//          do {
//            let generatedContent = try GeneratedContent(json: functionCall.arguments)
//            
//            try await executeFunctionCall(functionCall, continuation: continuation)
//          } catch {
////            throw SwiftAgent.ToolCallError(tool: <#T##any Tool#>, underlyingError: <#T##any Error#>)
//          }
        default:
          // TODO: Implement
          break
//          AppLogger.assistant.warning("Unsupported output received: \(output.jsonString())")
        }
      }

      // TODO: Implement tool call handling and state updates for store
    }

    return generatedTranscript
  }

  private func request(transcript: Core.Transcript) -> OpenAI.Request {
    return Request(
      model: .gpt4_1Mini,
      input: .list(transcript.toListItems(store: store)),
      instructions: instructions,
      safetyIdentifier: "",
      store: true,
      temperature: 0.0,
      tools: tools.map { .function(name: $0.name, description: $0.description, parameters: $0.parameters) }
    )
  }
}

private extension Core.Transcript {
  func toListItems(store: [String: Input.ListItem]) -> [Input.ListItem] {
    var listItems: [Input.ListItem] = []

    for entry in entries {
      switch entry {
      case let .prompt(prompt):
        listItems.append(
          Input.ListItem.message(role: .user, content: .text(prompt.content))
        )
      case let .toolCalls(toolCalls):
        // This is never user-generated, so it should be in the store
        for call in toolCalls.calls {
          if let item = store[call.id] { // call.id and not entry.id!
            listItems.append(item)
          } else {
            print("ToolCall: Not found in store: \(entry)")
          }
        }
      case .toolOutput:
        if let item = store[entry.id] {
          listItems.append(item)
        } else {
          print("ToolOutput: Not found in store: \(entry)")
        }
      case .response:
        if let item = store[entry.id] {
          listItems.append(item)
        } else {
          print("Response: Not found in store: \(entry)")
        }
      }
    }

    return listItems
  }
}
