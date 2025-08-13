# SwiftAgent

**Native Swift SDK for building autonomous AI agents with Apple's FoundationModels design philosophy**

SwiftAgent simplifies AI agent development by providing a clean, intuitive API that handles all the complexity of agent loops, tool execution, and provider communication. Inspired by Apple's FoundationModels framework, it brings the same elegant, declarative approach to cross-platform AI agent development.

---

## ✨ Features

- **🎯 Zero-Setup Agent Loops** — Handle autonomous agent execution with just a few lines of code
- **🔧 Native Tool Integration** — Use `@Generable` structs from FoundationModels as agent tools seamlessly  
- **🌐 Provider Agnostic** — Abstract interface supports multiple AI providers (OpenAI included, more coming)
- **📱 Apple-Native Design** — API inspired by FoundationModels for familiar, intuitive development
- **🚀 Modern Swift** — Built with Swift 6, async/await, and latest concurrency features
- **📊 Rich Logging** — Comprehensive, human-readable logging for debugging and monitoring
- **🎛️ Flexible Configuration** — Fine-tune generation options, tools, and provider settings

---

## 🚀 Quick Start

### Installation

Add SwiftAgent to your Swift project:

```swift
// Package.swift
dependencies: [
  .package(url: "https://github.com/SwiftedMind/SwiftAgent.git", branch: "main")
]
```

### Basic Usage

```swift
import SwiftAgent
import FoundationModels

// Configure your provider
let config = OpenAIProvider.Configuration.direct(apiKey: "your-api-key")
OpenAIProvider.Configuration.setDefaultConfiguration(config)

// Create an agent with tools
let agent = Agent<OpenAIProvider>(
  tools: [WeatherTool(), CalculatorTool()],
  instructions: "You are a helpful assistant."
)

// Run your agent
let response = try await agent.respond(
  to: "What's the weather like in San Francisco?",
  using: .gpt4o
)

print(response.content)
```

---

## 🛠️ Building Tools

Create tools using Apple's `@Generable` macro for type-safe, schema-free tool definitions:

```swift
struct WeatherTool: AgentTool {
  let name = "get_weather"
  let description = "Get current weather for a location"
  
  @Generable
  struct Arguments {
    @Guide(description: "City name")
    let city: String
    
    @Guide(description: "Temperature unit", .oneOf(["celsius", "fahrenheit"]))
    let unit: String = "celsius"
  }
  
  @Generable
  struct Output {
    let temperature: Double
    let condition: String
    let humidity: Int
  }
  
  func call(arguments: Arguments) async throws -> Output {
    // Your weather API implementation
    return Output(
      temperature: 22.5,
      condition: "sunny",
      humidity: 65
    )
  }
}
```

---

## 🏗️ Architecture

SwiftAgent abstracts the complexity of AI agent development:

```
┌─────────────────────────────────────────┐
│            Your Application             │
├─────────────────────────────────────────┤
│              SwiftAgent                 │  ← Clean, intuitive API
├─────────────────────────────────────────┤
│          Provider Abstraction           │  ← OpenAI, Anthropic, etc.
├─────────────────────────────────────────┤
│         Networking & JSON Logic         │  ← Hidden complexity
└─────────────────────────────────────────┘
```

**What SwiftAgent handles for you:**
- Agent execution loops and state management
- Tool call parsing and execution 
- Error handling and recovery strategies
- Provider-specific networking and protocols
- JSON schema generation and validation
- Response streaming and processing

**What you focus on:**
- Defining your tools with `@Generable` structs
- Writing your business logic
- Configuring your agent's behavior

---

## 📖 Advanced Usage

### Structured Output Generation

Generate structured data directly from agent responses:

```swift
@Generable
struct TaskList {
  let tasks: [Task]
  let priority: String
}

@Generable 
struct Task {
  let title: String
  let completed: Bool
}

let response = try await agent.respond(
  to: "Create a todo list for planning a vacation",
  generating: TaskList.self,
  using: .gpt4o
)

// response.content is now a strongly-typed TaskList
for task in response.content.tasks {
  print("- \(task.title)")
}
```

### Custom Generation Options

```swift
let options = GenerationOptions(
  maxTokens: 1000,
  temperature: 0.7,
  allowedSteps: 10
)

let response = try await agent.respond(
  to: "Help me analyze this data",
  using: .gpt4o,
  options: options
)
```

### Conversation History

Access full conversation transcripts:

```swift
// Continue conversations naturally
try await agent.respond(to: "What was my first question?")

// Access conversation history
for entry in agent.transcript.entries {
  switch entry {
  case .prompt(let prompt):
    print("User: \(prompt.content)")
  case .response(let response):
    print("Agent: \(response.content)")
  case .toolCalls(let calls):
    print("Tool calls: \(calls.calls.map(\.name))")
  // ... handle other entry types
  }
}
```

---

## 🔧 Configuration

### Provider Setup

```swift
// Direct API key
let config = OpenAIProvider.Configuration.direct(apiKey: "sk-...")

// Custom endpoint
let config = OpenAIProvider.Configuration.custom(
  apiKey: "sk-...",
  baseURL: URL(string: "https://api.custom-openai.com")!
)

OpenAIProvider.Configuration.setDefaultConfiguration(config)
```

### Logging

```swift
// Enable comprehensive logging
AgentConfiguration.setLoggingEnabled(true)

// Logs show:
// 🟢 Agent start — model=gpt-4o | tools=weather, calculator
// 🛠️ Tool call — weather [abc123] 
// 📤 Tool output — weather [abc123]
// ✅ Finished
```

---

## 🧪 Development Status

**⚠️ Work in Progress**: SwiftAgent is under active development. APIs may change, and breaking updates are expected. Use in production with caution.

---

## 📄 License

SwiftAgent is available under the MIT license. See [LICENSE](LICENSE) for more information.

---

## 🙏 Acknowledgments

- Inspired by Apple's [FoundationModels](https://developer.apple.com/documentation/foundationmodels) framework
- Built with the amazing Swift ecosystem and community

---

*Made with ❤️ for the Swift community*
