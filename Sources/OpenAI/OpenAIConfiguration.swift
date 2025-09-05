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

	/// Convenience builder for calling a proxy backend using a short‑lived bearer token.
	///
	/// This is intentionally NOT meant for calling OpenAI endpoints directly. It is
	/// designed for proxy backends that issue short‑lived, per‑"agent turn" access tokens
	/// and expect clients to present them as `Authorization: Bearer <token>`.
	///
	/// The method sets the `Authorization` header to `Bearer <token>` for every request
	/// and otherwise mirrors the standard HTTP client configuration used by the SDK.
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
		let encoder = JSONEncoder()

		// .sortedKeys is important to enable reliable cache hits!
		encoder.outputFormatting = .sortedKeys

		let decoder = JSONDecoder()
		// Keep defaults; OpenAI models define their own coding keys

		let interceptors = HTTPClientInterceptors(
			prepareRequest: { request in
				request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
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
}
