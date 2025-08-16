// By Dennis Müller

import Foundation
import FoundationModels

// MARK: - AgentTool

public protocol AgentTool<Envelope>: FoundationModels.Tool, Encodable
  where Output: ConvertibleToGeneratedContent, Output: ConvertibleFromGeneratedContent {
  /// App-defined wrapper used to *group* tool variants and *house* a tool run. If you don't need
  /// grouping or dispatch, you can rely on the provided `DefaultAgentToolEnvelope`.
  associatedtype Envelope = DefaultAgentToolEnvelope

  /// Produce the tool's grouping wrapper (the `Envelope`) for a given tool invocation.
  ///
  /// In apps, this commonly returns an enum case such as `.readMemory(run)` that carries the
  /// `AgentToolRun<Self>` so handlers have compile-time access to `arguments` and the `output` of the tool run.
  func envelope(for run: AgentToolRun<Self>) -> Envelope
}

public extension AgentTool {
  private var toolType: Self.Type { Self.self }

  func envelope(arguments: GeneratedContent, output: GeneratedContent?) throws -> Envelope {
    try envelope(for: run(for: arguments, output: output))
  }

  private func run(for arguments: GeneratedContent, output: GeneratedContent?) throws -> AgentToolRun<Self> {
    try AgentToolRun(arguments: self.arguments(from: arguments), output: self.output(from: output))
  }

  private func arguments(from generatedContent: GeneratedContent) throws -> Arguments {
    try toolType.Arguments(generatedContent)
  }

  private func output(from generatedContent: GeneratedContent?) throws -> Output? {
    guard let generatedContent else {
      return nil
    }

    return try toolType.Output(generatedContent)
  }
}

// MARK: - Default Envelope

/// An empty, no-op envelope for tools that do not participate in app-level routing/grouping.
///
/// If your app doesn't need a custom envelope, conformers can use this default and get an
/// implementation of `envelope(for:)` for free.
public struct DefaultAgentToolEnvelope {}

public extension AgentTool where Envelope == DefaultAgentToolEnvelope {
  func envelope(for run: AgentToolRun<Self>) -> DefaultAgentToolEnvelope {
    DefaultAgentToolEnvelope()
  }
}

// MARK: - AgentToolRun

/// A value describing one tool invocation: the input `arguments` plus an optional `output`.
///
/// - You can construct a run with only `arguments` (pre-execution) and attach `output` later, or
///   construct it with both after execution.
/// - `AgentToolRun` is used by envelopes to carry a concrete call through your app's routing layer.
public struct AgentToolRun<Tool: AgentTool> {
  /// The strongly typed inputs for this invocation.
  public let arguments: Tool.Arguments

  /// The tool's output, if available. `nil` when the run has not (yet) produced a result.
  public var output: Tool.Output?

  public init(arguments: Tool.Arguments, output: Tool.Output? = nil) {
    self.arguments = arguments
    self.output = output
  }
}

extension AgentToolRun: Sendable where Tool.Arguments: Sendable, Tool.Output: Sendable {}
extension AgentToolRun: Equatable where Tool.Arguments: Equatable, Tool.Output: Equatable {}
extension AgentToolRun: Hashable where Tool.Arguments: Hashable, Tool.Output: Hashable {}

// MARK: - Encoding

private enum AgentToolCodingKeys: String, CodingKey {
  case name
  case description
  case parameters
}

public extension AgentTool {
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: AgentToolCodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(description, forKey: .description)
    try container.encode(parameters, forKey: .parameters)
  }
}
