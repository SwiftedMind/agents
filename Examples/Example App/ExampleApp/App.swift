// By Dennis Müller

import FoundationModels
import SwiftAgent
import SwiftUI

@main
struct ExampleApp: App {
  init() {
    // Configure OpenAI adapter with API key
    let configuration = OpenAIAdapter.Configuration.direct(apiKey: Secret.OpenAI.apiKey)
    OpenAIAdapter.Configuration.setDefaultConfiguration(configuration)

    // Enable logging for development
    AgentConfiguration.setLoggingEnabled(true)
    AgentConfiguration.setNetworkLoggingEnabled(false)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

// MARK: - Tools

struct CalculatorTool: AgentTool {
  let name = "calculator"
  let description = "Performs basic mathematical calculations"

  @Generable
  struct Arguments {
    @Guide(description: "The first number")
    let firstNumber: Double

    @Guide(description: "The operation to perform (+, -, *, /)")
    let operation: String

    @Guide(description: "The second number")
    let secondNumber: Double
  }

  @Generable
  struct Output {
    let result: Double
    let expression: String
  }

  func call(arguments: Arguments) async throws -> Output {
    let result: Double

    switch arguments.operation {
    case "+":
      result = arguments.firstNumber + arguments.secondNumber
    case "-":
      result = arguments.firstNumber - arguments.secondNumber
    case "*":
      result = arguments.firstNumber * arguments.secondNumber
    case "/":
      guard arguments.secondNumber != 0 else {
        throw ToolError.divisionByZero
      }

      result = arguments.firstNumber / arguments.secondNumber
    default:
      throw ToolError.unsupportedOperation(arguments.operation)
    }

    let expression = "\(arguments.firstNumber) \(arguments.operation) \(arguments.secondNumber) = \(result)"
    return Output(result: result, expression: expression)
  }

  func resolve(_ run: AgentToolRun<CalculatorTool>) -> ResolvedToolRun {
    .calculator(run)
  }
}

struct WeatherTool: AgentTool {
  let name = "get_weather"
  let description = "Gets current weather information for a location"

  @Generable
  struct Arguments: Encodable {
    @Guide(description: "The city or location to get weather for")
    let location: String
  }

  @Generable
  struct Output {
    let location: String
    let temperature: Int
    let condition: String
    let humidity: Int
  }

  func call(arguments: Arguments) async throws -> Output {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 500_000_000)

    // Mock weather data based on location
    let mockWeatherData = [
      "london": ("London", 15, "Cloudy", 78),
      "paris": ("Paris", 18, "Sunny", 65),
      "tokyo": ("Tokyo", 22, "Rainy", 85),
      "new york": ("New York", 20, "Partly Cloudy", 72),
      "sydney": ("Sydney", 25, "Sunny", 55),
    ]

    let locationKey = arguments.location.lowercased()
    let weatherData = mockWeatherData[locationKey] ??
      (arguments.location, Int.random(in: 10...30), ["Sunny", "Cloudy", "Rainy"].randomElement()!, Int.random(in: 40...90))

    return Output(
      location: weatherData.0,
      temperature: weatherData.1,
      condition: weatherData.2,
      humidity: weatherData.3
    )
  }

  func resolve(_ run: AgentToolRun<WeatherTool>) -> ResolvedToolRun {
    .weather(run)
  }
}

struct CurrentTimeTool: AgentTool {
  let name = "get_current_time"
  let description = "Gets the current date and time"

  @Generable
  struct Arguments {
    @Guide(description: "Optional timezone (e.g., 'UTC', 'PST', 'EST'). Defaults to local time.")
    let timezone: String?
  }

  @Generable
  struct Output {
    let currentTime: String
    let timezone: String
    let timestamp: Double
  }

  func call(arguments: Arguments) async throws -> Output {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .long

    let timezoneString: String
    if let requestedTimezone = arguments.timezone {
      switch requestedTimezone.uppercased() {
      case "UTC":
        formatter.timeZone = TimeZone(identifier: "UTC")
        timezoneString = "UTC"
      case "PST":
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        timezoneString = "PST"
      case "EST":
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        timezoneString = "EST"
      default:
        formatter.timeZone = TimeZone.current
        timezoneString = TimeZone.current.identifier
      }
    } else {
      formatter.timeZone = TimeZone.current
      timezoneString = TimeZone.current.identifier
    }

    return Output(
      currentTime: formatter.string(from: now),
      timezone: timezoneString,
      timestamp: now.timeIntervalSince1970
    )
  }

  func resolve(_ run: AgentToolRun<CurrentTimeTool>) -> ResolvedToolRun {
    .currentTime(run)
  }
}

enum ResolvedToolRun {
  case calculator(AgentToolRun<CalculatorTool>)
  case weather(AgentToolRun<WeatherTool>)
  case currentTime(AgentToolRun<CurrentTimeTool>)
}

enum ToolError: Error, LocalizedError {
  case divisionByZero
  case unsupportedOperation(String)

  var errorDescription: String? {
    switch self {
    case .divisionByZero:
      return "Cannot divide by zero"
    case let .unsupportedOperation(operation):
      return "Unsupported operation: \(operation)"
    }
  }
}
