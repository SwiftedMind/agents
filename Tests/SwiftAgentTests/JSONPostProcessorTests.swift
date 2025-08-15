// By Dennis Müller

import Foundation
@testable import SwiftAgent
import Testing

@Suite("JSONPostProcessor Tests")
struct JSONPostProcessorTests {
  @Test func openAIComplianceTransformation() throws {
    // Arrange - Input JSON with optional parameters
    let inputJSON = """
    {
       "description":"Test function with optional parameters",
       "name":"test_function",
       "parameters":{
          "additionalProperties":false,
          "type":"object",
          "x-order":[
             "handle",
             "name",
             "status"
          ],
          "required":[
             "handle"
          ],
          "properties":{
             "handle":{
                "description":"Required parameter",
                "type":"string"
             },
             "name":{
                "description":"Optional parameter that should become nullable",
                "type":"string"
             },
             "status":{
                "description":"Another optional parameter",
                "type":"boolean"
             }
          },
          "title":"Arguments"
       }
    }
    """

    // Act - Process the JSON
    let result = try JSONPostProcessor.openAICompliance(for: inputJSON)

    // Assert - Parse the result to verify transformations
    let resultData = Data(result.utf8)
    let resultObject = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
    let parameters = resultObject["parameters"] as! [String: Any]
    let required = parameters["required"] as! [String]
    let properties = parameters["properties"] as! [String: Any]

    // Verify all parameters are now in required array, ordered by x-order
    #expect(required == ["handle", "name", "status"], "All parameters should be in required array")

    // Verify originally required parameter keeps its original type
    let handleProp = properties["handle"] as! [String: Any]
    let handleType = handleProp["type"] as! String
    #expect(handleType == "string", "Originally required parameter should keep its type")

    // Verify originally optional parameters become nullable
    let nameProp = properties["name"] as! [String: Any]
    let nameType = nameProp["type"] as! [String]
    #expect(nameType.contains("string"), "Optional parameter should still have its original type")
    #expect(nameType.contains("null"), "Optional parameter should have null added to type")
    #expect(nameType.count == 2, "Optional parameter type should have exactly 2 types")

    let statusProp = properties["status"] as! [String: Any]
    let statusType = statusProp["type"] as! [String]
    #expect(statusType.contains("boolean"), "Optional parameter should still have its original type")
    #expect(statusType.contains("null"), "Optional parameter should have null added to type")
    #expect(statusType.count == 2, "Optional parameter type should have exactly 2 types")
  }

  @Test func openAIComplianceWithExistingNullType() throws {
    // Arrange - Input JSON where a parameter already has null in its type
    let inputJSON = """
    {
       "name":"test_function",
       "parameters":{
          "type":"object",
          "required":[],
          "properties":{
             "optionalParam":{
                "type":["string", "null"]
             }
          }
       }
    }
    """

    // Act
    let result = try JSONPostProcessor.openAICompliance(for: inputJSON)

    // Assert - Verify null is not duplicated
    let resultData = Data(result.utf8)
    let resultObject = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
    let parameters = resultObject["parameters"] as! [String: Any]
    let properties = parameters["properties"] as! [String: Any]
    let paramProp = properties["optionalParam"] as! [String: Any]
    let paramType = paramProp["type"] as! [String]

    #expect(paramType.filter { $0 == "null" }.count == 1, "Null should appear only once in type array")
    #expect(paramType.contains("string"), "Original type should be preserved")
  }

  @Test func openAIComplianceWithoutXOrder() throws {
    // Arrange - Input JSON without x-order, should fall back to alphabetical ordering
    let inputJSON = """
    {
       "name":"test_function",
       "parameters":{
          "type":"object",
          "required":["alpha"],
          "properties":{
             "charlie":{
                "type":"string"
             },
             "alpha":{
                "type":"number"
             },
             "bravo":{
                "type":"boolean"
             }
          }
       }
    }
    """

    // Act
    let result = try JSONPostProcessor.openAICompliance(for: inputJSON)

    // Assert - Verify alphabetical ordering for parameters not in x-order
    let resultData = Data(result.utf8)
    let resultObject = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
    let parameters = resultObject["parameters"] as! [String: Any]
    let required = parameters["required"] as! [String]

    #expect(required == ["alpha", "bravo", "charlie"], "Parameters should be ordered alphabetically when no x-order")
  }
}
