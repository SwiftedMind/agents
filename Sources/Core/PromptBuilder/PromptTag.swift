///// A component for creating XML-style tags with optional attributes and indented content.
/////
///// `PromptTag` creates clearly defined sections using XML-style opening and closing tags.
///// This is particularly useful for creating structured prompts where different sections
///// need to be clearly delineated for AI processing.
/////
///// ## Example
///// ```swift
///// let tag = PromptTag("instructions", attributes: ["type": "system"]) {
/////   "Always be helpful and accurate"
/////   "Provide code examples when relevant"
///// }
///// ```
/////
///// ## Output Format
///// ```
///// <instructions type="system">
/////   Always be helpful and accurate
/////   Provide code examples when relevant
///// </instructions>
///// ```
//public struct PromptTag: PromptRepresentable {
//  private let name: String
//  private let attributes: [String: String]
//  private let components: [PromptRepresentable]
//
//  /// Creates a tag with multiple components.
//  ///
//  /// - Parameters:
//  ///   - name: The tag name
//  ///   - attributes: Optional attributes as key-value pairs
//  ///   - content: A closure that returns an array of prompt components
//  public init(
//    _ name: String,
//    attributes: [String: String] = [:],
//    @PromptBuilder content: () -> [PromptRepresentable]
//  ) {
//    self.name = name
//    self.attributes = attributes
//    components = content()
//  }
//
//  /// Creates a tag with a single component.
//  ///
//  /// - Parameters:
//  ///   - name: The tag name
//  ///   - attributes: Optional attributes as key-value pairs
//  ///   - content: A closure that returns a single prompt component
//  public init(
//    _ name: String,
//    attributes: [String: String] = [:],
//    @PromptBuilder content: () -> PromptRepresentable
//  ) {
//    self.name = name
//    self.attributes = attributes
//    components = [content()]
//  }
//
//  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
//    let indent = String(repeating: "  ", count: indentLevel)
//
//    var result = ""
//
//    // Opening tag
//    var openingTag = "<\(name)"
//    if !attributes.isEmpty {
//      let attributeString = attributes
//        .map { key, value in "\(key)=\"\(value)\"" }
//        .joined(separator: " ")
//      openingTag += " \(attributeString)"
//    }
//    openingTag += ">"
//    result += "\(indent)\(openingTag)\n"
//
//    // Content
//    let formattedComponents = components
//      .map { $0.formatted(indentLevel: indentLevel + 1, headingLevel: headingLevel) }
//      .joined(separator: "\n")
//
//    if !formattedComponents.isEmpty {
//      result += formattedComponents + "\n"
//    }
//
//    // Closing tag
//    result += "\(indent)</\(name)>"
//
//    return result
//  }
//}
