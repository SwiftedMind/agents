// By Dennis Müller

import Foundation
import FoundationModels
@_exported import Public

public typealias OpenAIContextualSession<Context: PromptContextSource> = ModelSession<OpenAIAdapter, Context>
public typealias OpenAISession = OpenAIContextualSession<NoContext>

public extension ModelSession {
  // MARK: - NoContext Initializers
  
  @MainActor static func openAI(
    tools: [any AgentTool] = [],
    instructions: String = "",
    apiKey: String
  ) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
    let configuration = OpenAIConfiguration.direct(apiKey: apiKey)
    let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
    return OpenAISession(adapter: adapter)
  }
  
  @MainActor static func openAI(
    tools: [any AgentTool] = [],
    instructions: String = "",
    configuration: OpenAIConfiguration,
  ) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
    let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
    return OpenAISession(adapter: adapter)
  }
  
  // MARK: - Context Initializers
  
  @MainActor static func openAI(
    tools: [any AgentTool] = [],
    instructions: String = "",
    context: Context.Type,
    configuration: OpenAIConfiguration,
  ) -> OpenAIContextualSession<Context> where Adapter == OpenAIAdapter {
    let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
    return OpenAIContextualSession(adapter: adapter)
  }

  @MainActor static func openAI(
    tools: [any AgentTool] = [],
    instructions: String = "",
    context: Context.Type,
    apiKey: String,
  ) -> OpenAIContextualSession<Context> where Adapter == OpenAIAdapter {
    let configuration = OpenAIConfiguration.direct(apiKey: apiKey)
    let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
    return OpenAIContextualSession(adapter: adapter)
  }
}
