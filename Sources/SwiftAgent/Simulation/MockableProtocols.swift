// By Dennis Müller

import Foundation
import FoundationModels

public protocol MockableAgentTool where Self: AgentTool, Arguments: Encodable {
  static func mockArguments() -> Arguments
  static func mockOutput() async throws -> Output
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
