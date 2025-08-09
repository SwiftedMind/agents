// By Dennis Müller

import Foundation
import OSLog

extension SwiftAgent {
  /// Internal logger for the SwiftAgent SDK.
  /// Defaults to disabled; enable via `SwiftAgent.setLoggingEnabled(_:)`.
  static var logger: Logger = Logger(OSLog.disabled)

  /// Enables or disables logging for the SDK.
  /// - Parameter enabled: Pass `true` to enable logging, `false` to disable.
  public static func setLoggingEnabled(_ enabled: Bool) {
    if enabled {
      // Use a stable subsystem; avoid relying on host app bundle identifier.
      logger = Logger(subsystem: "SwiftAgent", category: "SDK")
    } else {
      logger = Logger(OSLog.disabled)
    }
  }
}

