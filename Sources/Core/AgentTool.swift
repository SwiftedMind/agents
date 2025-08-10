// By Dennis Müller

import Foundation
import FoundationModels

public protocol AgentTool: FoundationModels.Tool where Output: ConvertibleToGeneratedContent {}
