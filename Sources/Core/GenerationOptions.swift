// By Dennis Müller

import Foundation
import FoundationModels

public struct GenerationOptions: Sendable, Equatable {
  public var temperature: Double? // Note: Not supported when using gpt-5
  public var maximumResponseTokens: Int?

  public init(
    temperature: Double? = nil,
    maximumResponseTokens: Int? = nil
  ) {
    self.temperature = temperature
    self.maximumResponseTokens = maximumResponseTokens
  }
}
