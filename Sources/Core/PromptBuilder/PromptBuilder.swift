// By Dennis Müller

import Foundation

// MARK: - Public Surface

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct Prompt: Sendable {
  /// Internal node tree we render later.
  package let nodes: [PromptNode]

  /// Creates an instance with the content you specify.
  public init(_ content: some PromptRepresentable) {
    self = content.promptRepresentation
  }

  /// Builder initializer.
  public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
    self = try content()
  }

  /// Render to a formatted string.
  public func formatted() -> String {
    Renderer.render(nodes, indentLevel: 0, headingLevel: 1)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Prompt: PromptRepresentable {
  public var promptRepresentation: Prompt { self }
}

// MARK: - Result Builder

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@resultBuilder
public struct PromptBuilder {
  /// 1) Normalize everything to Prompt at expression time.
  public static func buildExpression<P>(_ expression: P) -> Prompt where P: PromptRepresentable {
    expression.promptRepresentation
  }

  public static func buildExpression(_ expression: Prompt) -> Prompt { expression }

  /// 2) Now buildBlock can be uniform, no packs needed.
  public static func buildBlock(_ components: Prompt...) -> Prompt {
    Prompt(nodes: components.flatMap(\.nodes))
  }

  public static func buildArray(_ prompts: [Prompt]) -> Prompt {
    Prompt(nodes: prompts.flatMap(\.nodes))
  }

  public static func buildEither(first component: Prompt) -> Prompt { component }
  public static func buildEither(second component: Prompt) -> Prompt { component }
  public static func buildOptional(_ component: Prompt?) -> Prompt { component ?? .empty }
  public static func buildLimitedAvailability(_ prompt: Prompt) -> Prompt { prompt }
}

// MARK: - PromptRepresentable

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol PromptRepresentable {
  @PromptBuilder var promptRepresentation: Prompt { get }
}

/// Allow plain Strings in builders.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension String: PromptRepresentable {
  public var promptRepresentation: Prompt {
    Prompt(nodes: [.text(self)])
  }
}

// MARK: - Structured Types

/// Markdown-style section. Nested sections increment the `#` level.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PromptSection: PromptRepresentable, Sendable {
  public var title: String
  public var content: Prompt

  public init(_ title: String, @PromptBuilder _ content: () throws -> Prompt) rethrows {
    self.title = title
    self.content = try content()
  }

  public var promptRepresentation: Prompt {
    Prompt(nodes: [.section(title: title, children: content.nodes)])
  }
}

/// XML-like tag with optional attributes. Renders `<name a="1">…</name>`.
@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PromptTag: PromptRepresentable, Sendable {
  public var name: String
  public var attributes: [String: String]
  public var content: Prompt

  public init(
    _ name: String,
    attributes: [String: String] = [:],
    @PromptBuilder _ content: () throws -> Prompt
  ) rethrows {
    self.name = name
    self.attributes = attributes
    self.content = try content()
  }

  public var promptRepresentation: Prompt {
    Prompt(nodes: [.tag(name: name, attributes: attributes, children: content.nodes)])
  }
}

// MARK: - Internals

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Prompt {
  static let empty = Prompt(nodes: [])

  static func concatenate(_ prompts: [Prompt]) -> Prompt {
    Prompt(nodes: prompts.flatMap(\.nodes))
  }

  package init(nodes: [PromptNode]) {
    self.nodes = nodes
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
package enum PromptNode: Sendable {
  case text(String)
  case section(title: String, children: [PromptNode])
  case tag(name: String, attributes: [String: String], children: [PromptNode])
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
package enum Renderer {
  static func render(
    _ nodes: [PromptNode],
    indentLevel: Int,
    headingLevel: Int
  ) -> String {
    nodes
      .map { render(node: $0, indentLevel: indentLevel, headingLevel: headingLevel) }
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .joined(separator: "\n")
  }

  static func render(
    node: PromptNode,
    indentLevel: Int,
    headingLevel: Int
  ) -> String {
    switch node {
    case let .text(text):
      return indentString(indentLevel) + text

    case let .section(title, children):
      let header = headingPrefix(headingLevel) + " " + title
      let body = render(children, indentLevel: indentLevel, headingLevel: headingLevel + 1)
      if body.isEmpty { return indentString(indentLevel) + header }
      return indentString(indentLevel) + header + "\n" + body + "\n"

    case let .tag(name, attributes, children):
      let attrs = renderAttributes(attributes)
      let open = indentString(indentLevel) + "<" + name + attrs + ">"
      let body = render(children, indentLevel: indentLevel + 1, headingLevel: headingLevel)
      let close = indentString(indentLevel) + "</" + name + ">"
      if body.isEmpty { return open + close.dropFirst(close.hasPrefix("\n") ? 1 : 0) }
      return open + "\n" + body + "\n" + close
    }
  }

  private static func indentString(_ level: Int) -> String {
    String(repeating: "  ", count: max(0, level))
  }

  private static func headingPrefix(_ level: Int) -> String {
    String(repeating: "#", count: min(max(1, level), 6))
  }

  private static func renderAttributes(_ dict: [String: String]) -> String {
    guard !dict.isEmpty else { return "" }

    // Deterministic order for stable output.
    let parts = dict.sorted { $0.key < $1.key }.map { key, value in
      let escaped = value.xmlEscaped()
      return " \(key)=\"\(escaped)\""
    }
    return parts.joined()
  }
}

@available(iOS 26.0, macOS 26.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension String {
  func xmlEscaped() -> String {
    var out = self
    out = out.replacingOccurrences(of: "&", with: "&amp;")
    out = out.replacingOccurrences(of: "\"", with: "&quot;")
    out = out.replacingOccurrences(of: "'", with: "&apos;")
    out = out.replacingOccurrences(of: "<", with: "&lt;")
    out = out.replacingOccurrences(of: ">", with: "&gt;")
    return out
  }
}
