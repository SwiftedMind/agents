///// A component for creating markdown-style headings with hierarchical content.
/////
///// `PromptSection` generates markdown-compatible headings and automatically manages
///// heading levels for nested sections. It's ideal for creating well-structured documentation
///// or instructional content within prompts.
/////
///// ## Example
///// ```swift
///// let section = PromptSection("Getting Started") {
/////   "Welcome to our tutorial"
/////
/////   PromptSection("Prerequisites") {
/////     "Basic Swift knowledge"
/////     "Xcode installation"
/////   }
///// }
///// ```
/////
///// ## Output Format
///// ```
///// # Getting Started
///// Welcome to our tutorial
/////
///// ## Prerequisites
///// Basic Swift knowledge
/////
///// Xcode installation
///// ```
//public struct PromptSection: PromptRepresentable {
//  private let title: String
//  private let components: [PromptRepresentable]
//
//  /// Creates a section with multiple components.
//  ///
//  /// - Parameters:
//  ///   - title: The section heading text
//  ///   - content: A closure that returns an array of prompt components
//  public init(
//    _ title: String,
//    @PromptBuilder content: () -> [PromptRepresentable]
//  ) {
//    self.title = title
//    components = content()
//  }
//
//  /// Creates a section with a single component.
//  ///
//  /// - Parameters:
//  ///   - title: The section heading text
//  ///   - content: A closure that returns a single prompt component
//  public init(
//    _ title: String,
//    @PromptBuilder content: () -> PromptRepresentable
//  ) {
//    self.title = title
//    components = [content()]
//  }
//
//  public func formatted(indentLevel: Int, headingLevel: Int) -> String {
//    let indent = String(repeating: "  ", count: indentLevel)
//    let headingPrefix = String(repeating: "#", count: min(headingLevel, 6))
//    let titleLine = "\(indent)\(headingPrefix) \(title)\n"
//
//    let content = components
//      .map { $0.formatted(indentLevel: indentLevel, headingLevel: headingLevel + 1) }
//      .joined(separator: "\n\n")
//
//    return titleLine + content
//  }
//}
