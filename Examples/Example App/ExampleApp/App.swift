// By Dennis Müller

import FoundationModels
import SwiftAgent
import SwiftUI

@main
struct ExampleApp: App {
  init() {}

  var body: some Scene {
    WindowGroup {
      Text("Hello, World")
        .task {
          do {
            let configuration = OpenAIEngine.Configuration.openAIDirect(apiKey: Secret.OpenAI.apiKey)
            OpenAIEngine.Configuration.setDefaultConfiguration(configuration)

            let agent = SwiftAgent(using: .openAI, tools: [GetFavoriteNumbers()])
            try await agent.respond(to: "Give me my 5 favorite numbers")

          } catch {
            print(error)
          }
        }
    }
  }
}

// MARK: - Tools

@Generable
struct GetFavoriteNumbers: SwiftAgentTool {
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
