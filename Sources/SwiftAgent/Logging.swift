// By Dennis Müller

import Foundation
import OSLog

extension Logger {
  nonisolated(unsafe) static var main: Logger = .init(OSLog.disabled)
}
