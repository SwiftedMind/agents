// By Dennis Müller

import Foundation

/// Transforms a tool schema JSON so that:
/// 1) Every parameter appears in `"required"`, ordered by `"x-order"` if present.
/// 2) Any parameter that was previously optional becomes nullable:
///    `"type": "T"` → `"type": ["T", "null"]` (preserves existing `"null"`).
public enum JSONPostProcessor {
  public static func openAICompliance(for jsonString: String) throws -> String {
    let input = Data(jsonString.utf8)

    guard var root = try JSONSerialization.jsonObject(with: input) as? [String: Any] else {
      throw ProcessorError.invalidTopLevel
    }
    guard var parameters = root["parameters"] as? [String: Any] else {
      // TODO: Verify this is okay
      return jsonString
//      throw ProcessorError.missingParameters
    }
    guard var properties = parameters["properties"] as? [String: Any] else {
      throw ProcessorError.missingProperties
    }

    // Keep the original "required" to know what used to be optional.
    let originallyRequired = Set((parameters["required"] as? [String]) ?? [])

    // Build full required list, honoring x-order first, then remaining sorted.
    let xOrder = parameters["x-order"] as? [String] ?? []
    let propNames = Array(properties.keys)

    var ordered: [String] = xOrder.filter { properties[$0] != nil }
    ordered += propNames.filter { !ordered.contains($0) }.sorted()
    parameters["required"] = ordered

    // For fields that were previously optional, add "null" to their type.
    for name in propNames where !originallyRequired.contains(name) {
      guard var prop = properties[name] as? [String: Any],
            let currentType = prop["type"] else { continue }

      prop["type"] = Self.addingNullUnion(to: currentType)
      properties[name] = prop
    }

    parameters["properties"] = properties
    root["parameters"] = parameters

    let output = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted])
    guard let json = String(data: output, encoding: .utf8) else {
      throw ProcessorError.encodingFailed
    }

    return json
  }

  // MARK: - Helpers (private)

  private static func addingNullUnion(to value: Any) -> Any {
    // "type": "string" -> ["string", "null"]
    if let s = value as? String {
      return s == "null" ? ["null"] : [s, "null"]
    }

    // "type": ["string", "number"] -> ensure it contains "null"
    if let arr = value as? [Any] {
      let strings = arr.compactMap { $0 as? String }
      guard strings.count == arr.count else { return value }

      return strings.contains("null") ? strings : (strings + ["null"])
    }

    // Unknown shape; leave unchanged.
    return value
  }

  private enum ProcessorError: Error {
    case invalidTopLevel
    case missingParameters
    case missingProperties
    case encodingFailed
  }
}
