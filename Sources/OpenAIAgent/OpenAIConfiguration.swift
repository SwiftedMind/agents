// By Dennis Müller

import Foundation
import FoundationModels
import Internal

public extension OpenAIAdapter {
  struct Configuration: AdapterConfiguration {
    public var httpClient: HTTPClient
    public var responsesPath: String

    public init(httpClient: HTTPClient, responsesPath: String = "/v1/responses") {
      self.httpClient = httpClient
      self.responsesPath = responsesPath
    }

    /// Default configuration used by the protocol-mandated initializer.
    /// To customize, use the initializer that accepts a `Configuration`, or `Configuration.direct(...)`.
    public static var `default`: Configuration = {
      let baseURL = URL(string: "https://api.openai.com")!
      let config = HTTPClientConfiguration(
        baseURL: baseURL,
        defaultHeaders: [:],
        timeout: 60,
        jsonEncoder: JSONEncoder(),
        jsonDecoder: JSONDecoder(),
        interceptors: .init()
      )
      return Configuration(httpClient: URLSessionHTTPClient(configuration: config))
    }()

    /// Convenience builder for calling OpenAI directly with an API key.
    /// Users can alternatively point `baseURL` to their own backend and omit the apiKey.
    public static func direct(
      apiKey: String,
      baseURL: URL = URL(string: "https://api.openai.com")!,
      responsesPath: String = "/v1/responses"
    ) -> Configuration {
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      // Keep defaults; OpenAI models define their own coding keys

      let interceptors = HTTPClientInterceptors(
        prepareRequest: { request in
          request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        },
        onUnauthorized: { _, _, _ in
          // Let the caller decide how to refresh; default is not to retry
          false
        }
      )

      let config = HTTPClientConfiguration(
        baseURL: baseURL,
        defaultHeaders: [:],
        timeout: 60,
        jsonEncoder: encoder,
        jsonDecoder: decoder,
        interceptors: interceptors
      )

      return Configuration(httpClient: URLSessionHTTPClient(configuration: config), responsesPath: responsesPath)
    }
  }
}
