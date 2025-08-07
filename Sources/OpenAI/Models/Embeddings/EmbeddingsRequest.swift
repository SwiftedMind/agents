// By Dennis Müller

import Foundation

/// Request body for creating embeddings via OpenAI API.
public struct EmbeddingsRequest: Codable, Sendable {
  /// Input text or array of texts/tokens to embed.
  public var input: [String]
  /// ID of the model to use (e.g. "text-embedding-ada-002").
  public var model: String
  /// Number of dimensions for the output embeddings (optional).
  public var dimensions: Int?
  /// Format for returned embeddings: "float" or "base64".
  public var encodingFormat: String?
  /// Identifier for the end-user to help with abuse monitoring (optional).
  public var user: String?

  enum CodingKeys: String, CodingKey {
    case input
    case model
    case dimensions
    case encodingFormat = "encoding_format"
    case user
  }

  /// Convenience init for single-string input.
  public init(
    input: String,
    model: String,
    dimensions: Int? = nil,
    encodingFormat: String? = nil,
    user: String? = nil
  ) {
    self.input = [input]
    self.model = model
    self.dimensions = dimensions
    self.encodingFormat = encodingFormat
    self.user = user
  }

  /// Convenience init for multiple inputs.
  public init(
    inputs: [String],
    model: String,
    dimensions: Int? = nil,
    encodingFormat: String? = nil,
    user: String? = nil
  ) {
    input = inputs
    self.model = model
    self.dimensions = dimensions
    self.encodingFormat = encodingFormat
    self.user = user
  }
}

/// Top-level response for embeddings creation.
public struct EmbeddingsResponse: Codable, Sendable {
  /// Should always be "list".
  public var object: String
  /// Array of embedding result objects.
  public var data: [Embedding]
  /// Model used to generate embeddings.
  public var model: String
  /// Token usage details.
  public var usage: Usage
}

/// Single embedding entry in the response.
public struct Embedding: Codable, Sendable {
  /// Should always be "embedding".
  public var object: String
  /// Embedding vector values.
  public var embedding: [Float]
  /// Position index of this embedding in the input list.
  public var index: Int
}

/// Token usage breakdown.
public struct Usage: Codable, Sendable {
  /// Number of tokens in the prompt.
  public var promptTokens: Int
  /// Total tokens consumed.
  public var totalTokens: Int

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case totalTokens = "total_tokens"
  }
}
