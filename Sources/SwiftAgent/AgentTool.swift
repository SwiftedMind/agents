// By Dennis Müller

import Foundation
import FoundationModels

// MARK: - AgentTool

public protocol AgentTool<ResolvedToolRun>: FoundationModels.Tool, Encodable where Output: ConvertibleToGeneratedContent, Output: ConvertibleFromGeneratedContent {
  associatedtype ResolvedToolRun = Void

  func resolve(_ run: AgentToolRun<Self>) -> ResolvedToolRun
}

public extension AgentTool {
  package var toolType: Self.Type { Self.self }

  func resolvedTool(arguments: GeneratedContent, output: GeneratedContent?) throws -> ResolvedToolRun {
    try resolve(run(for: arguments, output: output))
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

public extension AgentTool where ResolvedToolRun == Void {
  func resolve(_ run: AgentToolRun<Self>) {
    ()
  }
}

// MARK: - AgentToolRun

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
