// By Dennis Müller

import Foundation
import FoundationModels

public protocol SwiftAgentTool: FoundationModels.Tool where Output: ConvertibleToGeneratedContent {}
