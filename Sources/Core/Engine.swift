// By Dennis Müller

import Foundation
import FoundationModels

@MainActor
public protocol Engine {
  associatedtype Configuration: Sendable
  init(
    tools: [any SwiftAgentTool],
    instructions: String,
    configuration: Configuration
  )
  
  func respond(
    to prompt: Core.Transcript.Prompt,
    transcript: Core.Transcript
  ) -> AsyncThrowingStream<Core.Transcript.Entry, any Error>
}
