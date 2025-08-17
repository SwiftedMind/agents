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
            let tools: [any AgentTool] = [GetFavoriteNumbersTool()]
            let agent = OpenAIAgent(supplying: PromptContext.self, tools: tools)
            
            let output = try await agent.respond(to: "Give me my 5 favorite numbers")
            print(output)
          } catch {
            
          }
        }
        .task {
          do {
            let configuration = OpenAIAdapter.Configuration.direct(apiKey: Secret.OpenAI.apiKey)
            OpenAIAdapter.Configuration.setDefaultConfiguration(configuration)

            AgentConfiguration.setLoggingEnabled(true)
            AgentConfiguration.setNetworkLoggingEnabled(true)

            // [any AgentTool] is sufficient if you don't need tool resolution
            let tools: [any AgentTool<ResolvedToolRun>] = [GetFavoriteNumbersTool()]

            let agent = OpenAIAgent(supplying: PromptContext.self, tools: tools)

            let output = try await agent.respond(to: "Give me my 5 favorite numbers", supplying: [.a, .a, .b]) { input, context in
              PromptTag("context", items: context)
              input
            }

            // Example of using the transcript resolver

            let toolResolver = agent.transcript.toolResolver(for: tools)
            var resolvedTools: [ResolvedToolRun] = []

            for entry in agent.transcript.entries {
              switch entry {
              case let .toolCalls(toolCalls):
                for toolCall in toolCalls.calls {
                  try resolvedTools.append(toolResolver.resolve(toolCall))
                }
              default:
                break
                // ...
              }
            }

            // Now we have type-safe, easy access to any tool runs, which is useful for passing it to the UI
            for resolvedTool in resolvedTools {
              switch resolvedTool {
              case let .getFavoriteNumbers(run):
                _ = run.arguments.count
                
                if let output = run.output {
                  _ = output.numbers
                }
              }
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
struct GetFavoriteNumbersTool: AgentTool {
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

  /// Only required to implement when you want to resolve tool runs in the transcript (type-safe tool groupings wrapping tool runs)
  func resolve(_ run: AgentToolRun<GetFavoriteNumbersTool>) -> ResolvedToolRun {
    .getFavoriteNumbers(run)
  }
}

enum ResolvedToolRun {
  case getFavoriteNumbers(AgentToolRun<GetFavoriteNumbersTool>)
}
