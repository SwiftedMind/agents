// By Dennis Müller

import Foundation
import FoundationModels
import Internal

public struct OpenAIConfiguration: AdapterConfiguration {
	var httpClient: HTTPClient
	var responsesPath: String

	init(httpClient: HTTPClient, responsesPath: String = "/v1/responses") {
		self.httpClient = httpClient
		self.responsesPath = responsesPath
	}

	/// Convenience builder for calling OpenAI directly with an API key.
	/// Users can alternatively point `baseURL` to their own backend and omit the apiKey.
	public static func direct(
		apiKey: String,
		baseURL: URL = URL(string: "https://api.openai.com")!,
		responsesPath: String = "/v1/responses",
	) -> OpenAIConfiguration {
		let encoder = JSONEncoder()

		// .sortedKeys is important to enable reliable cache hits!
		encoder.outputFormatting = .sortedKeys

		let decoder = JSONDecoder()
		// Keep defaults; OpenAI models define their own coding keys

		let interceptors = HTTPClientInterceptors(
			prepareRequest: { request in
				request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
			},
			onUnauthorized: { _, _, _ in
				// Let the caller decide how to refresh; default is not to retry
				false
			},
		)

		let config = HTTPClientConfiguration(
			baseURL: baseURL,
			defaultHeaders: [:],
			timeout: 60,
			jsonEncoder: encoder,
			jsonDecoder: decoder,
			interceptors: interceptors,
		)

		return OpenAIConfiguration(httpClient: URLSessionHTTPClient(configuration: config), responsesPath: responsesPath)
	}

	/// Convenience builder for calling a proxy backend using a session‑scoped bearer token.
	///
	/// This is intentionally NOT meant for calling OpenAI endpoints directly. Use this when your
	/// proxy backend provides a bearer token that remains valid for the entire `ModelSession` lifetime,
	/// and expects `Authorization: Bearer <token>` on requests.
	///
	/// If your token needs to change for each agent turn or response, prefer the
	/// ``direct(bearerToken:baseURL:responsesPath:)-(()->String,_,_)`` overload below so the freshest token is applied to every request.
	///
	/// - Parameters:
	///   - bearerToken: The raw bearer token to include in the `Authorization` header.
	///   - baseURL: The proxy backend `URL`.
	///   - responsesPath: The HTTP path used for responses. Defaults to `/v1/responses`.
	/// - Returns: A configured `OpenAIConfiguration` instance.
	public static func direct(
		bearerToken: String,
		baseURL: URL,
		responsesPath: String = "/v1/responses",
	) -> OpenAIConfiguration {
		direct(
			bearerToken: { bearerToken },
			baseURL: baseURL,
			responsesPath: responsesPath
		)
	}

	/// Convenience builder for calling a proxy backend using a dynamic bearer token provider.
	///
	/// Use this when your backend issues short‑lived tokens per agent turn/response, or when
	/// you otherwise need to resolve the token at request time. The provided `bearerTokenProvider`
	/// is invoked for each outgoing request so the freshest token is attached. On a 401 response,
	/// the request is retried once and the provider is invoked again before retrying.
	///
	/// - Parameters:
	///   - bearerToken: Async closure returning the current bearer token.
	///   - baseURL: The proxy backend `URL`.
	///   - responsesPath: The HTTP path used for responses. Defaults to `/v1/responses`.
	/// - Returns: A configured `OpenAIConfiguration` instance.
	public static func direct(
		bearerToken: @escaping @Sendable () async throws -> String,
		baseURL: URL,
		responsesPath: String = "/v1/responses",
	) -> OpenAIConfiguration {
		let encoder = JSONEncoder()

		// .sortedKeys is important to enable reliable cache hits!
		encoder.outputFormatting = .sortedKeys

		let decoder = JSONDecoder()
		// Keep defaults; OpenAI models define their own coding keys

		let interceptors = HTTPClientInterceptors(
			prepareRequest: { request in
				let token = try await bearerToken()
				request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			},
			onUnauthorized: { _, _, _ in
				// Let the caller decide how to refresh; default is to retry once with a freshly provided token
				true
			},
		)

		let config = HTTPClientConfiguration(
			baseURL: baseURL,
			defaultHeaders: [:],
			timeout: 60,
			jsonEncoder: encoder,
			jsonDecoder: decoder,
			interceptors: interceptors,
		)

		return OpenAIConfiguration(httpClient: URLSessionHTTPClient(configuration: config), responsesPath: responsesPath)
	}
}
