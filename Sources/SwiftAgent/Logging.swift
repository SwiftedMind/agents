// By Dennis Müller

import Foundation
import OSLog

extension Logger {
  @MainActor static var main: Logger = Logger(OSLog.disabled)
}
