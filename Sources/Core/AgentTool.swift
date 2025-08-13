// By Dennis Müller

import Foundation
import FoundationModels

public protocol AgentTool: FoundationModels.Tool, Encodable where Output: ConvertibleToGeneratedContent {}

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
