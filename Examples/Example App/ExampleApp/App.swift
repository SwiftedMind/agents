// By Dennis Müller

import FoundationModels
import OSLog
import SwiftAgent
import SwiftUI

@main
struct ExampleApp: App {
  init() {}

  var body: some Scene {
    WindowGroup {
      RootView()
        .task {
          do {
            let configuration = OpenAIEngine.Configuration.direct(apiKey: Secret.OpenAI.apiKey)
            OpenAIEngine.Configuration.setDefaultConfiguration(configuration)
            SwiftAgent.setLoggingEnabled(true)

            let agent = SwiftAgent(using: .openAI, tools: [GetFavoriteNumbers()])
            let output = try await agent.respond(to: "Give me my 5 favorite numbers", generating: NumbersOutput.self)
            print("HERE RESULT: ", output.content)
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
