// By Dennis Müller

import Foundation
import FoundationModels
@_exported import SwiftAgent

public typealias OpenAIAgent = Agent<OpenAIAdapter, NoContext>
public typealias OpenAIAgentWith<Source: PromptContextSource> = Agent<OpenAIAdapter, Source>

public extension Agent where Adapter == OpenAIAdapter, Context == NoContext {
  convenience init(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) where Context == NoContext {
    let adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
    self.init(adapter: adapter)
  }

  static func withContext<NewContext: PromptContextSource>(
    _ source: NewContext.Type,
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: Adapter.Configuration = .default
  ) -> Agent<OpenAIAdapter, NewContext> {
    let adapter = Adapter(tools: tools, instructions: instructions, configuration: configuration)
    return Agent<OpenAIAdapter, NewContext>(adapter: adapter)
  }
}
