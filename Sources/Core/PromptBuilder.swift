/// A protocol that represents a prompt.
public protocol PromptRepresentable {
  /// An instance that represents a prompt.
  @PromptBuilder var promptRepresentation: Prompt { get }
}

/// A type that represents a prompt builder.
@resultBuilder
public struct PromptBuilder {
  /// Creates a builder with the a block.
  public static func buildBlock() -> Prompt {
    return Prompt(content: "")
  }

  public static func buildBlock<P: PromptRepresentable>(_ p: P) -> Prompt {
    return p.promptRepresentation
  }

  public static func buildBlock<P1: PromptRepresentable, P2: PromptRepresentable>(_ p1: P1, _ p2: P2) -> Prompt {
    let parts = [p1.promptRepresentation.content, p2.promptRepresentation.content]
    return Prompt(content: parts.joined(separator: "\n"))
  }

  public static func buildBlock<P1: PromptRepresentable, P2: PromptRepresentable, P3: PromptRepresentable>(_ p1: P1, _ p2: P2, _ p3: P3) -> Prompt {
    let parts = [p1.promptRepresentation.content, p2.promptRepresentation.content, p3.promptRepresentation.content]
    return Prompt(content: parts.joined(separator: "\n"))
  }

  public static func buildBlock<P1: PromptRepresentable, P2: PromptRepresentable, P3: PromptRepresentable, P4: PromptRepresentable>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4) -> Prompt {
    let parts = [p1.promptRepresentation.content, p2.promptRepresentation.content, p3.promptRepresentation.content, p4.promptRepresentation.content]
    return Prompt(content: parts.joined(separator: "\n"))
  }

  public static func buildBlock<P1: PromptRepresentable, P2: PromptRepresentable, P3: PromptRepresentable, P4: PromptRepresentable, P5: PromptRepresentable>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5) -> Prompt {
    let parts = [p1.promptRepresentation.content, p2.promptRepresentation.content, p3.promptRepresentation.content, p4.promptRepresentation.content, p5.promptRepresentation.content]
    return Prompt(content: parts.joined(separator: "\n"))
  }

  /// Creates a builder with the an array of prompts.
  public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt {
    let content = prompts.map { $0.promptRepresentation.content }.joined(separator: "\n")
    return Prompt(content: content)
  }

  /// Creates a builder with the first component.
  public static func buildEither(first component: some PromptRepresentable) -> Prompt {
    return component.promptRepresentation
  }

  /// Creates a builder with the second component.
  public static func buildEither(second component: some PromptRepresentable) -> Prompt {
    return component.promptRepresentation
  }

  /// Creates a builder with an optional component.
  public static func buildOptional(_ component: Prompt?) -> Prompt {
    return component ?? Prompt(content: "")
  }

  /// Creates a builder with a limited availability prompt.
  public static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt {
    return prompt.promptRepresentation
  }

  /// Creates a builder with an expression.
  public static func buildExpression<P>(_ expression: P) -> P where P: PromptRepresentable {
    return expression
  }

  /// Creates a builder with a prompt expression.
  public static func buildExpression(_ expression: Prompt) -> Prompt {
    return expression
  }
}

/// A prompt from a person to the model.
///
/// Prompts can contain content written by you, an outside source, or input directly from people using
/// your app. You can initialize a `Prompt` from a string literal:
///
/// ```swift
/// let prompt = Prompt("What are miniature schnauzers known for?")
/// ```
///
/// Use ``PromptBuilder`` to dynamically control the prompt's content based on your app's state. The
/// code below shows if the Boolean is `true`, the prompt includes a second line of text:
///
/// ```swift
/// let responseShouldRhyme = true
/// let prompt = Prompt {
///     "Answer the following question from the user: \(userInput)"
///     if responseShouldRhyme {
///         "Your response MUST rhyme!"
///     }
/// }
/// ```
public struct Prompt: Sendable {
  fileprivate let content: String

  /// Creates an instance with the content you specify.
  public init(_ content: some PromptRepresentable) {
    self.content = content.promptRepresentation.content
  }

  /// Creates a prompt with direct string content.
  init(content: String) {
    self.content = content
  }

  /// Creates a prompt using the PromptBuilder.
  public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
    self = try content()
  }
}

extension Prompt: PromptRepresentable {
  /// An instance that represents a prompt.
  public var promptRepresentation: Prompt {
    return self
  }
}

extension String: PromptRepresentable {
  /// An instance that represents a prompt.
  public var promptRepresentation: Prompt {
    return Prompt(content: self)
  }
}

// MARK: - Public API

public extension Prompt {
  /// Returns the string representation of the prompt for use with LLMs.
  var stringValue: String {
    return content
  }
}
