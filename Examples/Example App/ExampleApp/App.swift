// By Dennis Müller

import FoundationModels
import OSLog
import SwiftAgent
import SwiftUI

enum PromptContext: String, SwiftAgent.PromptContext, SwiftAgent.PromptRepresentable {
  case a = "A"
  case b = "B"
}

@main
struct ExampleApp: App {
  init() {}

  var body: some Scene {
    WindowGroup {
      RootView()
        .task {
          do {
            let configuration = OpenAIAdapter.Configuration.direct(apiKey: Secret.OpenAI.apiKey)
            OpenAIAdapter.Configuration.setDefaultConfiguration(configuration)
            
            AgentConfiguration.setLoggingEnabled(true)
            AgentConfiguration.setNetworkLoggingEnabled(true)

            let agent = OpenAIAgent(supplying: PromptContext.self, tools: [GetFavoriteNumbers()])

            let output = try await agent.respond(to: "Give me my 5 favorite numbers", supplying: [.a, .a, .b]) { input, context in
              PromptTag("context", items: context)
              input
            }

            print("Result:", output.content)
          } catch {
            print("Error \(error)")
          }
        }
    }
  }
}

// MARK: - Tools

@Generable
struct NumbersOutput {
  var numbers: [Int]
}

@Generable
struct GetFavoriteNumbers: AgentTool {
  let name = "get_favorite_numbers"
  let description = "Fetches the user's favorite numbers"

  @Generable
  struct Arguments {
    @Guide(description: "The amount of numbers to fetch", .range(1...10))
    let count: Int
  }

  @Generable
  struct Output {
    var numbers: [Int]
  }

  func call(arguments: Arguments) async throws -> Output {
    var output = Output(numbers: Array(repeating: 0, count: arguments.count))
    for index in output.numbers.indices {
      output.numbers[index] = Int.random(in: 0...1000)
    }
    return output
  }
}
