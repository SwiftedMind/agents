// By Dennis Müller

import Foundation
import FoundationModels
import Public

public protocol MockableAgentTool<Tool>: Sendable where Tool.Arguments: Encodable {
  associatedtype Tool: AgentTool
  
  var tool: Tool { get }
  
  func mockArguments() -> Tool.Arguments
  func mockOutput() async throws -> Tool.Output
}

public protocol MockableGenerable where Self: Generable {
  associatedtype Content: Generable
  static func mockContent() -> Content
}

extension String: MockableGenerable {
  public static func mockContent() -> String {
    // Is not used by the simulation adapter
    ""
  }
}
