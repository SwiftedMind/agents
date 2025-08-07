//// By Dennis Müller
//
//import Contacts
//import Foundation
//import FoundationModels
//import Playgrounds
//
//struct FindContacts: Tool {
//  let name = "findContacts"
//  let description = "Finds a specific number of contacts"
//
//  func call(arguments: Arguments) async throws -> String {
//    return "Okay"
//  }
//}
//
//@Generable
//struct Arguments {
//  @Guide(description: "The number of contacts to get", .range(1...10))
//  let count: Int
//  
//  let value: String?
//}
//
//#Playground {
//  let session = LanguageModelSession(tools: [FindContacts()])
//  let content = try GeneratedContent(json: #"{"count": 5"#)
//  
//  Arguments.generationSchema
//  
//  session.respond(to: "", generating: Arguments.self)
//  
//  let abc = try Arguments(content)
//  abc.count
//  abc.value
//}
//
//// TODO: Write Feedback to ask to make GenerationSchema Equatable in some way
