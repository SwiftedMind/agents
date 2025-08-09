// By Dennis Müller

import Foundation
import FoundationModels

@MainActor
public protocol Engine {
  init(
    tools: [any SwiftAgentTool],
    instructions: String
  )
  
  func respond(
    to prompt: Core.Transcript.Prompt,
    transcript: Core.Transcript
  ) -> AsyncThrowingStream<Core.Transcript.Entry, any Error>
}
