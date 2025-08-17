// By Dennis Müller

import Foundation
import OSLog

public enum AgentConfiguration {
  /// Enables or disables logging for the SDK.
  /// - Parameter enabled: Pass `true` to enable logging, `false` to disable.
  @MainActor public static func setLoggingEnabled(_ enabled: Bool) {
    if enabled {
      Logger.main = Logger(subsystem: "SwiftAgent", category: "SDK")
    } else {
      Logger.main = Logger(OSLog.disabled)
    }
  }

  /// Enables or disables network request/response logging.
  /// - Parameter enabled: Pass `true` to enable network logging, `false` to disable.
  @MainActor public static func setNetworkLoggingEnabled(_ enabled: Bool) {
    NetworkLog.isEnabled = enabled
  }
}
