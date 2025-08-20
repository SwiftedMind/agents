# Todos

## High Priority

- Implement `JSONPostProcessor` for OpenAI tool schema compliance and add unit tests
- Add `allowedSteps` to `OpenAIAdapter.GenerationOptions`; remove hardcoded step limit
- Fix OpenAI request: set `maxToolCalls` correctly (do not use `maxOutputTokens`)
- Align README examples with current API naming (`maxOutputTokens`, no generic `GenerationOptions`)
- Add Agent loop tests: text, structured responses; tool call happy path

## Medium Priority

- Cancellation: expose `cancel()` and propagate to HTTP; add tests
- Retry & backoff on 5xx/429; per‑request timeout configuration
- Tool execution timeouts and retries; optional parallel tool calls
- Token usage and finish reason surfaces; pluggable metrics sink
- Transcript persistence (encode/decode) and basic summarization API

## Low Priority

- Anthropic adapter (parity with tools + structured output)
- Example App v1: streaming UI, tool runs, settings
- RAG hooks via `PromptContext`; simple demo vector store integration
- API polish: per‑tool config, redaction defaults, improved error messages

