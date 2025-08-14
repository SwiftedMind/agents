//
//  for.swift
//  SwiftAgent
//
//  Created by Dennis Müller on 14.08.25.
//


// By Dennis Müller

import Foundation

// MARK: - Core Protocol

/// A protocol for elements that can be part of a structured prompt message.
///
/// Types conforming to `MessageRepresentable` can be used within the `MessageBuilder` result builder
/// to create hierarchical, well-formatted prompt structures. The protocol provides a standardized
/// way to format content with proper indentation and heading levels.
///
/// ## Example
/// ```swift
/// struct CustomComponent: MessageRepresentable {
///   let text: String
///
///   func formatted(indentLevel: Int, headingLevel: Int) -> String {
///     let indent = String(repeating: "  ", count: indentLevel)
///     return "\(indent)Custom: \(text)"
///   }
/// }
/// ```
public protocol MessageRepresentable {
  /// Formats the component as a string with the specified indentation and heading level.
  ///
  /// - Parameters:
  ///   - indentLevel: The number of indentation levels (each level = 2 spaces)
  ///   - headingLevel: The heading level for markdown-style headers (1-6)
  /// - Returns: A formatted string representation of the component
  func formatted(indentLevel: Int, headingLevel: Int) -> String
}

// MARK: - Result Builder

/// A result builder that enables declarative syntax for constructing structured prompt messages.
///
/// `MessageBuilder` allows you to compose complex prompts using a SwiftUI-like declarative syntax.
/// It automatically handles the conversion of various types into `MessageRepresentable` components.
///
/// ## Example
/// ```swift
/// let message = UserMessage {
///   "Welcome message"
///
///   if includeInstructions {
///     MessageSection("Instructions") {
///       "Follow these steps"
///       "Be careful with the details"
///     }
///   }
///
///   MessageBlock(title: "data") {
///     "Important information here"
///   }
/// }
/// ```
@resultBuilder
public struct UserMessageBuilder {
  public static func buildBlock() -> [MessageRepresentable] {
    []
  }
  
  public static func buildBlock(_ components: MessageRepresentable...) -> [MessageRepresentable] {
    components
  }
  
  public static func buildArray(_ components: [MessageRepresentable]) -> [MessageRepresentable] {
    components
  }
  
  public static func buildOptional(_ component: [MessageRepresentable]?) -> [MessageRepresentable] {
    component ?? []
  }
  
  public static func buildEither(first component: [MessageRepresentable]) -> [MessageRepresentable] {
    component
  }
  
  public static func buildEither(second component: [MessageRepresentable]) -> [MessageRepresentable] {
    component
  }
  
  public static func buildExpression(_ expression: MessageRepresentable) -> MessageRepresentable {
    expression
  }
  
  public static func buildExpression(_ expression: String) -> MessageRepresentable {
    MessageText(expression)
  }
  
  public static func buildExpression(_ expression: [MessageRepresentable]) -> MessageRepresentable {
    MessageGroup(expression)
  }
  
  public static func buildFinalResult(_ component: [any MessageRepresentable]) -> String {
    component.formatted(indentLevel: 0, headingLevel: 0)
  }
}

// MARK: - Main Prompt Type

/// The main container for structured prompt messages, providing a declarative interface for building complex prompts.
///
/// `UserMessage` serves as the root container for all prompt components. It uses the `MessageBuilder`
/// result builder to provide a clean, declarative syntax for constructing hierarchical prompt structures.
/// The formatted output can be used directly with AI language models or other text processing systems.
///
/// ## Example
/// ```swift
/// let prompt = UserMessage {
///   MessageSection("System Instructions") {
///     "You are a helpful coding assistant"
///     "Always provide working examples"
///   }
///
///   MessageBlock(title: "context") {
///     "The user is learning Swift programming"
///   }
///
///   MessageBlock(title: "query") {
///     "Explain how optionals work in Swift"
///   }
/// }
///
/// print(prompt.formatted())
/// ```
///
/// ## Output Format
/// The formatted output uses markdown-style headings and XML-like tags for structured blocks:
/// ```
/// # System Instructions
/// You are a helpful coding assistant
/// Always provide working examples
///
/// <context>
///   The user is learning Swift programming
/// </context>
///
/// <query>
///   Explain how optionals work in Swift
/// </query>
/// ```
public struct UserMessage: MessageRepresentable {
  private let components: [MessageRepresentable]
  
  /// Creates a user message with multiple components.
  ///
  /// - Parameter content: A closure that returns an array of message components
  public init(@UserMessageBuilder content: () -> [MessageRepresentable]) {
    components = content()
  }
  
  /// Creates a user message with a single component.
  ///
  /// - Parameter content: A closure that returns a single message component
  public init(@UserMessageBuilder content: () -> MessageRepresentable) {
    components = [content()]
  }
  
  /// Formats the entire message as a string.
  ///
  /// - Parameters:
  ///   - indentLevel: The starting indentation level (default: 0)
  ///   - headingLevel: The starting heading level (default: 1)
  /// - Returns: A formatted string representation of the complete message
  public func formatted(indentLevel: Int = 0, headingLevel: Int = 1) -> String {
    components
      .map { $0.formatted(indentLevel: indentLevel, headingLevel: headingLevel) }
      .joined(separator: "\n\n")
  }
}

// MARK: - Basic Components

/// A simple text component that represents a single line or paragraph of content.
///
/// `MessageText` is the most basic building block for prompt messages. It automatically
/// handles proper indentation based on its position in the component hierarchy.
///
/// ## Example
/// ```swift
/// let text = MessageText("This is a simple text component")
/// print(text.formatted(indentLevel: 1, headingLevel: 1))
/// // Output: "  This is a simple text component"
/// ```
///
/// ## Note
/// You typically don't need to create `MessageText` instances directly, as string literals
/// are automatically converted to `MessageText` within `MessageBuilder` contexts.
public struct MessageText: MessageRepresentable {
  private let text: String
  
  /// Creates a text component with the specified content.
  ///
  /// - Parameter text: The text content to display
  public init(_ text: String) {
    self.text = text
  }
  
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentLevel)
    return indent + text
  }
}

/// A container that groups multiple message components together without adding additional formatting.
///
/// `MessageGroup` is useful for logically grouping related components while maintaining
/// the same formatting level. It's automatically used when arrays of components are
/// provided in `MessageBuilder` contexts.
///
/// ## Example
/// ```swift
/// let group = MessageGroup([
///   MessageText("First item"),
///   MessageText("Second item"),
///   MessageText("Third item")
/// ])
/// ```
public struct MessageGroup: MessageRepresentable {
  private let components: [MessageRepresentable]
  
  /// Creates a group containing the specified components.
  ///
  /// - Parameter components: An array of message components to group together
  public init(_ components: [MessageRepresentable]) {
    self.components = components
  }
  
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    components
      .map { $0.formatted(indentLevel: indentLevel, headingLevel: headingLevel) }
      .joined(separator: "\n\n")
  }
}

// MARK: - Structured Components

/// A structured block component that wraps content in XML-like tags with optional descriptions.
///
/// `MessageBlock` creates clearly defined sections using XML-style opening and closing tags.
/// This is particularly useful for creating structured prompts where different sections
/// need to be clearly delineated for AI processing.
///
/// ## Example
/// ```swift
/// let block = MessageBlock(title: "instructions", description: "System directives") {
///   "Always be helpful and accurate"
///   "Provide code examples when relevant"
/// }
/// ```
///
/// ## Output Format
/// ```
/// <instructions description="System directives">
///   Always be helpful and accurate
///
///   Provide code examples when relevant
/// </instructions>
/// ```
public struct MessageBlock: MessageRepresentable {
  private let title: String
  private let description: String?
  private let components: [MessageRepresentable]
  
  /// Creates a message block with multiple components.
  ///
  /// - Parameters:
  ///   - title: The tag name for the block
  ///   - description: An optional description attribute for the opening tag
  ///   - content: A closure that returns an array of message components
  public init(
    title: String,
    description: String? = nil,
    @UserMessageBuilder content: () -> [MessageRepresentable]
  ) {
    self.title = title
    self.description = description
    components = content()
  }
  
  /// Creates a message block with a single component.
  ///
  /// - Parameters:
  ///   - title: The tag name for the block
  ///   - description: An optional description attribute for the opening tag
  ///   - content: A closure that returns a single message component
  public init(
    title: String,
    description: String? = nil,
    @UserMessageBuilder content: () -> MessageRepresentable
  ) {
    self.title = title
    self.description = description
    components = [content()]
  }
  
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentLevel)
    
    var result = ""
    
    // Opening tag
    if let description = description {
      result += "\(indent)<\(title) description=\"\(description)\">\n"
    } else {
      result += "\(indent)<\(title)>\n"
    }
    
    // Content
    let formattedComponents = components
      .map { $0.formatted(indentLevel: indentLevel + 1, headingLevel: headingLevel) }
      .joined(separator: "\n")
    
    if !formattedComponents.isEmpty {
      result += formattedComponents + "\n"
    }
    
    // Closing tag
    result += "\(indent)</\(title)>"
    
    return result
  }
}

/// A section component that creates markdown-style headings with hierarchical content.
///
/// `MessageSection` generates markdown-compatible headings and automatically manages
/// heading levels for nested sections. It's ideal for creating well-structured documentation
/// or instructional content within prompts.
///
/// ## Example
/// ```swift
/// let section = MessageSection("Getting Started") {
///   "Welcome to our tutorial"
///
///   MessageSection("Prerequisites") {
///     "Basic Swift knowledge"
///     "Xcode installation"
///   }
/// }
/// ```
///
/// ## Output Format
/// ```
/// # Getting Started
/// Welcome to our tutorial
///
/// ## Prerequisites
/// Basic Swift knowledge
///
/// Xcode installation
/// ```
public struct MessageSection: MessageRepresentable {
  private let title: String
  private let components: [MessageRepresentable]
  
  /// Creates a message section with multiple components.
  ///
  /// - Parameters:
  ///   - title: The section heading text
  ///   - content: A closure that returns an array of message components
  public init(
    _ title: String,
    @UserMessageBuilder content: () -> [MessageRepresentable]
  ) {
    self.title = title
    components = content()
  }
  
  /// Creates a message section with a single component.
  ///
  /// - Parameters:
  ///   - title: The section heading text
  ///   - content: A closure that returns a single message component
  public init(
    _ title: String,
    @UserMessageBuilder content: () -> MessageRepresentable
  ) {
    self.title = title
    components = [content()]
  }
  
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentLevel)
    let headingPrefix = String(repeating: "#", count: min(headingLevel, 6))
    let titleLine = "\(indent)\(headingPrefix) \(title)\n"
    
    let content = components
      .map { $0.formatted(indentLevel: indentLevel, headingLevel: headingLevel + 1) }
      .joined(separator: "\n\n")
    
    return titleLine + content
  }
}

/// A component for displaying input-output examples in a standardized format.
///
/// `MessageExample` is designed to showcase example interactions, making it easy to provide
/// clear demonstrations of expected behavior or format. This is particularly useful for
/// few-shot prompting techniques.
///
/// ## Example
/// ```swift
/// let example = MessageExample(
///   input: "How do I create an optional in Swift?",
///   output: "You can create an optional by adding '?' after the type: var name: String?"
/// )
/// ```
///
/// ## Output Format
/// ```
/// Input: How do I create an optional in Swift?
/// Output: You can create an optional by adding '?' after the type: var name: String?
/// ```
public struct MessageExample: MessageRepresentable {
  private let input: String
  private let output: String
  
  /// Creates an example with input and output text.
  ///
  /// - Parameters:
  ///   - input: The example input or question
  ///   - output: The expected output or answer
  public init(input: String, output: String) {
    self.input = input
    self.output = output
  }
  
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentLevel)
    return """
    \(indent)Input: \(input)
    \(indent)Output: \(output)
    """
  }
}

// MARK: - Convenience Extensions

/// Extends `String` to conform to `MessageRepresentable` for seamless integration with `MessageBuilder`.
///
/// This extension allows string literals to be used directly within message builder contexts
/// without explicit conversion to `MessageText` components.
///
/// ## Example
/// ```swift
/// let message = UserMessage {
///   "This string is automatically handled"  // Becomes MessageText internally
///   "No need for explicit MessageText() wrapper"
/// }
/// ```
extension String: MessageRepresentable {
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentLevel)
    return indent + self
  }
}

/// Extends arrays of `MessageRepresentable` to support direct formatting.
///
/// This extension enables arrays of message components to be formatted as a group,
/// with each component separated by double line breaks for clear visual separation.
///
/// ## Example
/// ```swift
/// let components: [MessageRepresentable] = [
///   MessageText("First component"),
///   MessageText("Second component")
/// ]
/// print(components.formatted(indentLevel: 0, headingLevel: 1))
/// ```
extension Array: MessageRepresentable where Element == MessageRepresentable {
  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
    map { $0.formatted(indentLevel: indentLevel, headingLevel: headingLevel) }
      .joined(separator: "\n\n")
  }
}
