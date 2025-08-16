// By Dennis Müller

import Foundation
import struct FoundationModels.GeneratedContent

public struct TranscriptView<Metadata, Envelope> where Metadata: ProviderMetadata, Envelope: Equatable, Envelope: Sendable {
  public typealias Resolver = (Transcript<Metadata>.ToolCall, Transcript<Metadata>) throws -> Envelope

  private let base: Transcript<Metadata>
  private let resolver: Resolver

  public init(base: Transcript<Metadata>, tools: [any AgentTool<Envelope>]) {
    self.base = base
    resolver = NameIndexedResolver(tools: tools).resolve
  }

  public init(base: Transcript<Metadata>, resolve: @escaping Resolver) {
    self.base = base
    resolver = resolve
  }

  // MARK: Entries

  public enum Entry: Sendable, Identifiable, Equatable {
    case prompt(Prompt)
    case reasoning(Reasoning)
    case toolRun(ToolRun)
    case response(Response)

    public var id: String {
      switch self {
      case let .prompt(p): return p.id
      case let .reasoning(r): return r.id
      case let .toolRun(t): return t.id
      case let .response(r): return r.id
      }
    }
  }

  public struct Prompt: Sendable, Identifiable, Equatable {
    public var id: String
    public var content: String
    // Intentionally minimal: SDK can't know about "user-typed vs injected".
    // Apps can annotate via separate stores if desired.

    public init(id: String, content: String) {
      self.id = id
      self.content = content
    }
  }

  public struct Reasoning: Sendable, Identifiable, Equatable {
    public var id: String
    public var summary: [String]

    public init(id: String, summary: [String]) {
      self.id = id
      self.summary = summary
    }
  }

  public struct ToolRun: Sendable, Identifiable, Equatable {
    public var id: String
    public var envelope: Envelope

    public init(id: String, envelope: Envelope) {
      self.id = id
      self.envelope = envelope
    }
  }

  public struct Response: Sendable, Identifiable, Equatable {
    public var id: String
    public var segment: Segment

    public init(id: String, segment: Segment) {
      self.id = id
      self.segment = segment
    }

    public enum Segment: Sendable, Equatable {
      case text(String)
      case structure(GeneratedContent)
    }
  }
}

private extension TranscriptView {
  func computeEntries() -> [Entry] {
    var result: [Entry] = []
    result.reserveCapacity(base.entries.count)

    for entry in base.entries {
      switch entry {
      case let .prompt(p):
        result.append(.prompt(
          Prompt(id: p.id, content: p.content)
        ))

      case let .reasoning(r):
        result.append(.reasoning(
          Reasoning(id: r.id, summary: r.summary)
        ))

      case let .toolCalls(calls):
        for call in calls.calls {
          if let toolEntry = try? makeToolRun(for: call) {
            result.append(toolEntry)
          } else {
            // Graceful degradation: skip unknown tools rather than crashing.
            // Apps can log this via a customizable hook later.
          }
        }

      case .toolOutput:
        // Handled as a "look-ahead" when processing .toolCalls
        break

      case let .response(r):
        for seg in r.segments {
          switch seg {
          case let .text(t):
            result.append(.response(Response(id: t.id, segment: .text(t.content))))
          case let .structure(s):
            result.append(.response(Response(id: s.id, segment: .structure(s.content))))
          }
        }
      }
    }

    return result
  }

  func makeToolRun(for call: Transcript<Metadata>.ToolCall) throws -> Entry {
    let env = try resolver(call, base)
    return .toolRun(ToolRun(id: call.id, envelope: env))
  }
}

private struct NameIndexedResolver<Envelope, Metadata> where Metadata: ProviderMetadata {
  private let byName: [String: any AgentTool<Envelope>]

  init(tools: [any AgentTool<Envelope>]) {
    byName = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
  }

  func resolve(
    call: Transcript<Metadata>.ToolCall,
    in transcript: Transcript<Metadata>
  ) throws -> Envelope {
    guard let tool = byName[call.toolName] else {
      throw ToolResolutionError.unknownTool(name: call.toolName)
    }

    let output = findOutput(for: call.id, in: transcript)
    return try tool.envelope(arguments: call.arguments, output: output)
  }

  private func findOutput(
    for callId: String,
    in transcript: Transcript<Metadata>
  ) -> GeneratedContent? {
    for entry in transcript.entries {
      if case let .toolOutput(o) = entry, o.callId == callId {
        switch o.segment {
        case let .text(t): return GeneratedContent(t.content)
        case let .structure(s): return s.content
        }
      }
    }
    return nil
  }
}

public enum ToolResolutionError: Error, Sendable, Equatable {
  case unknownTool(name: String)
}
