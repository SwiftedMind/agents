// By Dennis Müller

import Foundation

public protocol PromptContext: Sendable, Equatable {}

public struct EmptyPromptContext: PromptContext {}
