// By Dennis Müller

import FoundationModels
import OpenAIAgent
import SwiftUI

struct RootView: View {
  @State private var userInput = ""
  @State private var agentResponse = ""
  @State private var toolCallsUsed: [String] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var agent: OpenAIAgentWith<ContextSource>?

  // MARK: - Tools

  private var tools: [any AgentTool<ResolvedToolRun>] = [
    CalculatorTool(),
    WeatherTool(),
  ]

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section("Agent") {
          TextField("Ask me anything…", text: $userInput, axis: .vertical)
            .lineLimit(3...6)
            .submitLabel(.send)
            .disabled(isLoading)
            .onSubmit {
              Task { await askAgent() }
            }

          Button {
            Task { await askAgent() }
          } label: {
            Text("Ask Agent")
          }
          .disabled(isLoading || userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        if isLoading {
          Section {
            HStack {
              ProgressView()
              Text("Thinking…")
            }
            .foregroundStyle(.secondary)
          }
        }

        if let errorMessage {
          Section("Error") {
            Label {
              Text(errorMessage)
            } icon: {
              Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            }
            .accessibilityLabel(String(localized: "Error"))
          }
        }

        if !agentResponse.isEmpty {
          Section("Response") {
            Text(agentResponse)
              .textSelection(.enabled)
          }
        }

        if !toolCallsUsed.isEmpty {
          Section("Tools Used") {
            ForEach(toolCallsUsed, id: \.self) { call in
              Text(call)
            }
          }
        }
      }
      .animation(.default, value: isLoading)
      .animation(.default, value: toolCallsUsed)
      .animation(.default, value: errorMessage)
      .animation(.default, value: agentResponse)
      .navigationTitle("SwiftAgent")
      .navigationBarTitleDisplayMode(.inline)
      .formStyle(.grouped)
    }
    .task { setupAgent() }
  }

  // MARK: - Setup

  private func setupAgent() {
    agent = OpenAIAgent.withContext(
      ContextSource.self,
      tools: tools,
      instructions: """
      You are a helpful assistant with access to several tools.
      Use the available tools when appropriate to help answer questions.
      Be concise but informative in your responses.
      """
    )
  }

  // MARK: - Actions

  @MainActor
  private func askAgent() async {
    guard let agent, !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    userInput = ""
    isLoading = true
    errorMessage = nil
    agentResponse = ""
    toolCallsUsed = []

    do {
      
      let response = try await agent.respond(
        to: userInput,
        supplying: [.currentDate(Date())],
        options: .init(include: [.encryptedReasoning])
      ) { input, context in
        PromptTag("context") {
          for source in context.sources {
            switch source {
            case .currentDate(let date):
              PromptTag("current-date") { date }
            }
          }
        }
        
        PromptTag("input") {
          input
        }
      }
      agentResponse = response.content

      let toolResolver = agent.transcript.toolResolver(for: tools)
      for entry in response.addedEntries {
        if case let .toolCalls(toolCalls) = entry {
          for toolCall in toolCalls.calls {
            do {
              let resolvedTool = try toolResolver.resolve(toolCall)
              switch resolvedTool {
              case let .calculator(run):
                if let output = run.output {
                  toolCallsUsed.append("Calculator: \(output.expression)")
                }
              case let .weather(run):
                if let output = run.output {
                  toolCallsUsed.append(
                    "Weather: \(output.location) - \(output.temperature)°C, \(output.condition)"
                  )
                }
              }
            } catch {
              print(error)
            }
          }
        }
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}

#Preview {
  NavigationStack {
    RootView()
  }
  .preferredColorScheme(.dark)
}
