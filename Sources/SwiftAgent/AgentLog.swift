// By Dennis Müller

import Foundation
import OSLog

/// Centralized, human-friendly logging for agent runs and tool calls.
///
/// Uses the SDK's `Logger.main` instance to emit concise, readable console output
/// with consistent formatting. JSON payloads are pretty-printed when possible.
enum AgentLog {
  /// Logs the start of an agent run.
  static func start(model: String, toolNames: [String], promptPreview: String?) {
    let tools = toolNames.isEmpty ? "-" : toolNames.joined(separator: ", ")
    let preview = promptPreview.map { "\($0.prefix(180))" } ?? "-"
    Logger.main.info(
      "🟢 \(String(localized: "Agent start")) — model=\(model, privacy: .public) | tools=\(tools, privacy: .public) | prompt=\(preview, privacy: .public)"
    )
  }

  /// Logs that the provider is requesting the next response step.
  static func stepRequest(step: Int) {
    Logger.main.debug("↗️ \(String(localized: "Request step")) #\(step, privacy: .public)")
  }

  /// Logs a plain message output from the model.
  static func outputMessage(text: String, status: String) {
    let preview = text.trimmingCharacters(in: .whitespacesAndNewlines)
    Logger.main.info(
      "💬 \(String(localized: "Output")) — status=\(status, privacy: .public)\n\(preview, privacy: .public)"
    )
  }

  /// Logs a structured (JSON) output from the model.
  static func outputStructured(json: String, status: String) {
    Logger.main.info(
      "📦 \(String(localized: "Structured output")) — status=\(status, privacy: .public)\n\(pretty(json: json), privacy: .public)"
    )
  }

  /// Logs that a tool call was requested by the model.
  static func toolCall(name: String, callId: String, argumentsJSON: String) {
    Logger.main.info(
      "🛠️ \(String(localized: "Tool call")) — \(name, privacy: .public) [\(callId, privacy: .public)]\nargs:\n\(pretty(json: argumentsJSON), privacy: .public)"
    )
  }

  /// Logs tool output after the tool completed successfully.
  static func toolOutput(name: String, callId: String, outputJSONOrText: String) {
    let body = pretty(json: outputJSONOrText)
    Logger.main.info(
      "📤 \(String(localized: "Tool output")) — \(name, privacy: .public) [\(callId, privacy: .public)]\n\(body, privacy: .public)"
    )
  }

  /// Logs a reasoning summary if available.
  static func reasoning(summary: [String]) {
    guard !summary.isEmpty else { return }

    let joined = summary.joined(separator: "\n• ")
    Logger.main.debug(
      "🧠 \(String(localized: "Reasoning"))\n• \(joined, privacy: .public)"
    )
  }

  /// Logs that the run finished.
  static func finish() {
    Logger.main.info("✅ \(String(localized: "Finished"))")
  }

  /// Logs an error during the run.
  static func error(_ error: any Error, context: String? = nil) {
    let ctx = context ?? "-"
    let errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    Logger.main.error(
      "⛔️ \(String(localized: "Error")) — \(ctx, privacy: .public): \(errorMessage, privacy: .public)"
    )
  }

  /// Pretty-prints a JSON string if possible, otherwise returns the input.
  static func pretty(json: String) -> String {
    guard let data = json.data(using: .utf8) else { return json }

    do {
      let object = try JSONSerialization.jsonObject(with: data)
      let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
      return String(data: pretty, encoding: .utf8) ?? json
    } catch {
      return json
    }
  }
}
