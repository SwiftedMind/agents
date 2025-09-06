// By Dennis Müller

import Foundation
import FoundationModels
@_exported import SwiftAgent

/// A convenience type alias for creating contextual OpenAI-powered ModelSession instances.
///
/// This type alias represents a ModelSession configured with the OpenAI adapter and a specific
/// context type that conforms to ``PromptContextSource``. Use this when you need to inject
/// context data into your prompts for more sophisticated AI interactions.
///
/// Example usage with custom context:
/// ```swift
/// struct UserContext: PromptContextSource {
///   let userName: String
///   let preferences: [String]
/// }
///
/// let session: OpenAIContextualSession<UserContext> = .openAI(
///   tools: [WeatherTool()],
///   instructions: "You are a helpful assistant",
///   context: UserContext.self,
///   apiKey: "your-api-key"
/// )
/// ```
public typealias OpenAIContextualSession<Context: PromptContextSource> = ModelSession<OpenAIAdapter, Context>

/// A convenience type alias for creating simple OpenAI-powered ModelSession instances without context.
///
/// This type alias represents a ModelSession configured with the OpenAI adapter and no context
/// injection. Use this for straightforward AI interactions that don't require additional context data.
///
/// Example usage:
/// ```swift
/// let session: OpenAISession = .openAI(
///   tools: [CalculatorTool()],
///   instructions: "You are a math assistant",
///   apiKey: "your-api-key"
/// )
/// ```
public typealias OpenAISession = OpenAIContextualSession<NoContext>

public extension ModelSession {
	// MARK: - NoContext Initializers

	/// Creates a simple OpenAI-powered ModelSession without context using an API key.
	///
	/// This is the most straightforward way to create an OpenAI session for basic interactions.
	/// The session will be configured with a direct connection to OpenAI's API using the provided API key.
	///
	/// - Parameter tools: An array of tools the AI agent can use during conversations. Defaults to an empty array.
	/// - Parameter instructions: System instructions that define the AI's behavior and personality. Defaults to an empty string.
	/// - Parameter apiKey: Your OpenAI API key for authentication.
	/// - Returns: A configured ``OpenAISession`` ready for AI interactions.
	///
	/// Example:
	/// ```swift
	/// let session = ModelSession.openAI(
	///   tools: [WeatherTool(), CalculatorTool()],
	///   instructions: "You are a helpful assistant that can check weather and do calculations.",
	///   apiKey: "sk-your-api-key-here"
	/// )
	/// ```
	@MainActor static func openAI(
		tools: [any AgentTool] = [],
		instructions: String = "",
		apiKey: String,
	) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
		let configuration = OpenAIConfiguration.direct(apiKey: apiKey)
		let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
		return OpenAISession(adapter: adapter)
	}

    /// Creates an OpenAI-powered ModelSession without context using a dynamic bearer token provider.
    ///
    /// Use this when connecting to a proxy backend that issues short‑lived tokens per agent
    /// turn/response, or when you otherwise need to resolve the token at request time. The
    /// `bearerTokenProvider` is invoked for every request and on a single 401 retry.
	///
	/// - Parameters:
	///   - tools: Tools available to the agent.
	///   - instructions: System instructions describing the agent behavior.
	///   - baseURL: Proxy backend base `URL`.
	///   - responsesPath: Response path on the backend. Defaults to `/v1/responses`.
	///   - bearerTokenProvider: Async closure returning the current bearer token.
	/// - Returns: A configured ``OpenAISession``.
    @MainActor static func openAI(
        tools: [any AgentTool] = [],
        instructions: String = "",
        baseURL: URL,
        responsesPath: String = "/v1/responses",
        bearerTokenProvider: @escaping @Sendable () async throws -> String
    ) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
        let configuration = OpenAIConfiguration.direct(
            bearerTokenProvider: bearerTokenProvider,
            baseURL: baseURL,
            responsesPath: responsesPath
        )
        let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
        return OpenAISession(adapter: adapter)
    }

    /// Creates an OpenAI-powered ModelSession without context using a fixed bearer token.
    ///
    /// Use this when your proxy backend provides a token that remains valid for the entire
    /// session lifetime. If your token changes per agent turn/response, prefer the
    /// `bearerTokenProvider` variant.
	///
	/// - Parameters are the same as the provider overload, except `bearerToken` is fixed.
	@MainActor static func openAI(
		tools: [any AgentTool] = [],
		instructions: String = "",
		baseURL: URL,
		responsesPath: String = "/v1/responses",
		bearerToken: String
	) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
		let configuration = OpenAIConfiguration.direct(
			bearerToken: bearerToken,
			baseURL: baseURL,
			responsesPath: responsesPath
		)
		let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
		return OpenAISession(adapter: adapter)
	}

	/// Creates a simple OpenAI-powered ModelSession without context using a custom configuration.
	///
	/// This method allows you to create an OpenAI session with advanced configuration options,
	/// such as custom endpoints, models, or proxy settings. Use this when you need more control
	/// over the OpenAI connection than the basic API key method provides.
	///
	/// - Parameter tools: An array of tools the AI agent can use during conversations. Defaults to an empty array.
	/// - Parameter instructions: System instructions that define the AI's behavior and personality. Defaults to an empty string.
	/// - Parameter configuration: A custom ``OpenAIConfiguration`` that defines how to connect to OpenAI services.
	/// - Returns: A configured ``OpenAISession`` ready for AI interactions.
	///
	/// Example:
	/// ```swift
	/// let configuration = OpenAIConfiguration.direct(apiKey: "your-api-key")
	/// let session = ModelSession.openAI(
	///   tools: [DatabaseTool()],
	///   instructions: "You are a database assistant",
	///   configuration: configuration
	/// )
	/// ```
	@MainActor static func openAI(
		tools: [any AgentTool] = [],
		instructions: String = "",
		configuration: OpenAIConfiguration,
	) -> OpenAISession where Adapter == OpenAIAdapter, Context == NoContext {
		let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
		return OpenAISession(adapter: adapter)
	}

	// MARK: - Context Initializers

	/// Creates a contextual OpenAI-powered ModelSession with custom configuration.
	///
	/// This method creates an OpenAI session that supports context injection, allowing you to
	/// provide additional data to your prompts through a type that conforms to ``PromptContextSource``.
	/// This is useful for sophisticated AI interactions that require user data, preferences,
	/// or other contextual information to be available to the AI.
	///
	/// - Parameter tools: An array of tools the AI agent can use during conversations. Defaults to an empty array.
	/// - Parameter instructions: System instructions that define the AI's behavior and personality. Defaults to an empty string.
	/// - Parameter context: The type of context that will be injected into prompts. Must conform to `PromptContextSource`.
	/// - Parameter configuration: A custom ``OpenAIConfiguration`` that defines how to connect to OpenAI services.
	/// - Returns: A configured ``OpenAIContextualSession` ready for AI interactions with context injection.
	///
	/// Example:
	/// ```swift
	/// struct UserContext: PromptContextSource {
	///   let userName: String
	///   let preferences: [String]
	/// }
	///
	/// let configuration = OpenAIConfiguration.direct(apiKey: "your-api-key")
	/// let session = ModelSession.openAI(
	///   tools: [PersonalizedTool()],
	///   instructions: "You are a personalized assistant",
	///   context: UserContext.self,
	///   configuration: configuration
	/// )
	/// ```
	@MainActor static func openAI(
		tools: [any AgentTool] = [],
		instructions: String = "",
		context: Context.Type,
		configuration: OpenAIConfiguration,
	) -> OpenAIContextualSession<Context> where Adapter == OpenAIAdapter {
		let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
		return OpenAIContextualSession(adapter: adapter)
	}

	/// Creates a contextual OpenAI-powered ModelSession using an API key.
	///
	/// This is the most convenient way to create a contextual OpenAI session for sophisticated
	/// AI interactions. The session supports context injection through a type that conforms to
	/// ``PromptContextSource``, and will be configured with a direct connection to OpenAI's API
	/// using the provided API key.
	///
	/// - Parameter tools: An array of tools the AI agent can use during conversations. Defaults to an empty array.
	/// - Parameter instructions: System instructions that define the AI's behavior and personality. Defaults to an empty string.
	/// - Parameter context: The type of context that will be injected into prompts. Must conform to `PromptContextSource`.
	/// - Parameter apiKey: Your OpenAI API key for authentication.
	/// - Returns: A configured ``OpenAIContextualSession`` ready for AI interactions with context injection.
	///
	/// Example:
	/// ```swift
	/// struct AppContext: PromptContextSource {
	///   let currentUser: User
	///   let appVersion: String
	///   let systemSettings: [String: Any]
	/// }
	///
	/// let session = ModelSession.openAI(
	///   tools: [UserManagementTool(), SystemInfoTool()],
	///   instructions: "You are an app assistant with access to user and system information",
	///   context: AppContext.self,
	///   apiKey: "sk-your-api-key-here"
	/// )
	/// ```
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

    /// Creates a contextual OpenAI-powered ModelSession using a dynamic bearer token provider.
    ///
    /// Use this when your proxy backend issues short‑lived tokens per agent turn/response, or
    /// when token resolution must happen at request time. The provider runs for each request and
    /// again on a single 401 retry.
	///
	/// - Parameters:
	///   - tools: Tools available to the agent.
	///   - instructions: System instructions describing the agent behavior.
	///   - context: The context type to inject into prompts.
	///   - baseURL: Proxy backend base `URL`.
	///   - responsesPath: Response path on the backend. Defaults to `/v1/responses`.
	///   - bearerTokenProvider: Async closure returning the current bearer token.
	/// - Returns: A configured ``OpenAIContextualSession``.
    @MainActor static func openAI(
        tools: [any AgentTool] = [],
        instructions: String = "",
        context: Context.Type,
        baseURL: URL,
        responsesPath: String = "/v1/responses",
        bearerTokenProvider: @escaping @Sendable () async throws -> String
    ) -> OpenAIContextualSession<Context> where Adapter == OpenAIAdapter {
        let configuration = OpenAIConfiguration.direct(
            bearerTokenProvider: bearerTokenProvider,
            baseURL: baseURL,
            responsesPath: responsesPath
        )
        let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
        return OpenAIContextualSession(adapter: adapter)
    }

    /// Creates a contextual OpenAI-powered ModelSession using a fixed bearer token.
    ///
    /// Use this when your token remains valid for the entire session lifetime. If your token
    /// changes per agent turn/response, prefer the `bearerTokenProvider` variant.
	@MainActor static func openAI(
		tools: [any AgentTool] = [],
		instructions: String = "",
		context: Context.Type,
		baseURL: URL,
		responsesPath: String = "/v1/responses",
		bearerToken: String
	) -> OpenAIContextualSession<Context> where Adapter == OpenAIAdapter {
		let configuration = OpenAIConfiguration.direct(
			bearerToken: bearerToken,
			baseURL: baseURL,
			responsesPath: responsesPath
		)
		let adapter = OpenAIAdapter(tools: tools, instructions: instructions, configuration: configuration)
		return OpenAIContextualSession(adapter: adapter)
	}
}
