// By Dennis Müller

import Foundation
import FoundationModels

public struct GenerationOptions: Sendable, Equatable {
  public var temperature: Double? // Note: Not supported when using gpt-5
  public var maximumResponseTokens: UInt?

  public init(
    temperature: Double? = nil,
    maximumResponseTokens: UInt? = nil
  ) {
    self.temperature = temperature
    self.maximumResponseTokens = maximumResponseTokens
  }
}
