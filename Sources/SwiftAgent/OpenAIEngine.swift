// By Dennis Müller

import Core
import Foundation
import FoundationModels
import OpenAI

public final class OpenAIEngine: Engine {
  /// Maps Transcript.Entry.ID to an OpenAI ListItem.
  private var store: [String: Input.ListItem] = [:]

  private var tools: [any FoundationModels.Tool]
  private var instructions: String = ""

  public init(
    tools: [any FoundationModels.Tool],
    instructions: String
  ) {
    self.tools = tools
    self.instructions = instructions
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

      // TODO: Implement some kind of network client
      let response: Response = try await networkClient.responses(request)

      for output in response.output {
        switch output {
        case let .message(message):
          let response = Transcript.Response(segments: [.text(Transcript.TextSegment(content: message.text))])
          
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

      // TODO: Implement
    }

    // TODO: Implement error
  }

  private func request(transcript: Core.Transcript) -> Request {
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
