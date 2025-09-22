// By Dennis Müller

import Foundation
import OpenAI


// TODO: How to properly handle refusal content?
extension Components.Schemas.OutputContent {
	var asText: String {
		switch self {
		case let .OutputTextContent(outputTextContent):
			return outputTextContent.text
		case let .RefusalContent(refusalContent):
			return refusalContent.refusal
		}
	}
}
