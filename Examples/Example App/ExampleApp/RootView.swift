// By Dennis Müller

import FoundationModels
import SwiftAgent
import SwiftUI

struct RootView: View {
  @State private var userInput = ""
  @State private var agentResponse = ""
  @State private var toolCallsUsed: [String] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var agent: OpenAIAgent<EmptyPromptContext>?

  private let tools: [any AgentTool<ResolvedToolRun>] = [
    CalculatorTool(),
    WeatherTool(),
    CurrentTimeTool(),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          // Header
          VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 48))
              .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
              Text("SwiftAgent Demo")
                .font(.title.bold())

              Text("Ask me anything and I'll use my tools to help you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
          }
          .padding(.top, 20)

          // Input Section
          VStack(alignment: .leading, spacing: 20) {
            Text("What can I help you with?")
              .font(.title2.weight(.semibold))

            VStack(spacing: 16) {
              TextField("Ask me anything...", text: $userInput, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.quaternary, lineWidth: 1))
                .lineLimit(3...6)

              Button {
                Task {
                  await askAgent()
                }
              } label: {
                HStack(spacing: 12) {
                  if isLoading {
                    ProgressView()
                  } else {
                    Image(systemName: "paperplane.fill")
                  }

                  Text(isLoading ? "Thinking..." : "Ask Agent")
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)
              .disabled(isLoading || userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
          }
          .padding()
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
          .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))

          // Results Section
          if !agentResponse.isEmpty || !toolCallsUsed.isEmpty || errorMessage != nil {
            VStack(alignment: .leading, spacing: 24) {
              Text("Response")
                .font(.title2.weight(.semibold))

              if let errorMessage = errorMessage {
                VStack(alignment: .leading, spacing: 12) {
                  Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.headline)

                  Text(errorMessage)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                )
              } else {
                VStack(spacing: 16) {
                  if !toolCallsUsed.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                      Label("Tools Used", systemImage: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.blue)
                        .font(.headline)

                      VStack(alignment: .leading, spacing: 8) {
                        ForEach(toolCallsUsed, id: \.self) { toolCall in
                          HStack {
                            Circle()
                              .fill(.blue.opacity(0.6))
                              .frame(width: 6, height: 6)

                            Text(toolCall)
                              .font(.subheadline)
                              .foregroundStyle(.primary)
                          }
                        }
                      }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.blue.opacity(0.3), lineWidth: 1))
                  }

                  if !agentResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                      Label("Agent Response", systemImage: "message.fill")
                        .foregroundStyle(.green)
                        .font(.headline)

                      Text(agentResponse)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.green.opacity(0.3), lineWidth: 1))
                  }
                }
              }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
          }
        }
        .padding(.horizontal, 20)
      }
      .navigationBarHidden(true)
      .background(.regularMaterial)
    }
    .task {
      setupAgent()
    }
  }

  private func setupAgent() {
    agent = OpenAIAgent(tools: tools, instructions: """
    You are a helpful assistant with access to several tools. 
    Use the available tools when appropriate to help answer questions.
    Be concise but informative in your responses.
    """)
  }

  @MainActor
  private func askAgent() async {
    guard let agent = agent, !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    isLoading = true
    errorMessage = nil
    agentResponse = ""
    toolCallsUsed = []

    do {
      let response = try await agent.respond(to: userInput)
      agentResponse = response.content

      // Extract tool calls for display
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
                  toolCallsUsed.append("Weather: \(output.location) - \(output.temperature)°C, \(output.condition)")
                }
              case let .currentTime(run):
                if let output = run.output {
                  toolCallsUsed.append("Time: \(output.currentTime) (\(output.timezone))")
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
  RootView()
    .preferredColorScheme(.dark)
}
