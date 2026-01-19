In this stage, you'll add support for detecting tool calls from the LLM's response, and executing the `Read` tool call.

### Executing `Read` tool call

When the LLM decides to use a tool, the response message will contain a `tool_calls` array. In this stage, you'll only execute a single `Read` tool call.

Here is an example of the response structure:

```json
{
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": null,
        "tool_calls": [
          {
            "id": "call_abc123",
            "type": "function",
            "function": {
              "name": "Read",
              "arguments": "{\"file_path\": \"/path/to/file.txt\"}"
            }
          }
        ]
      },
      "finish_reason": "tool_calls"
    }
  ]
}
```

The descriptions of the fields are:

- `tool_calls`: The array of tool calls to make.
- Each tool call has:
  - `id`: A unique identifier for this tool call
  - `type`: The type of tool call (always `"function"` for function tools)
  - `function`: Contains the function details:
    - `name`: The name of the function to call (e.g., `"Read"`)
    - `arguments`: A JSON string containing the function parameters

When you detect a `tool_calls` array in the response:

1. Extract the tool call: Get the first tool call from `message.tool_calls[0]`.
2. Parse the function name: Read `function.name` to determine which tool to execute.
3. Parse the arguments: Parse `function.arguments` to get the parameters.
4. Execute the tool: Call the appropriate tool function with the parsed arguments.
5. Output the result: Print the tool execution result to stdout.

### Tests

The tester will create a random file `/path/to/main.py`.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Print ONLY the contents of the file `/path/to/main.py`. No backticks either."
<file contents>
```

The tester will assert that the output matches the exact contents of the file.

### Notes

- For this stage, you only need to print the result of the first tool call. The tester will only test against prompts that will result in one tool call in the response from the LLM. We'll get to handling multiple tool calls in the next stage.

- For this stage, you only need to print the result of the tool call. You don't need to send the result back to the LLM. We'll get to implementing the agent loop in the next stage.

- [OpenRouter API Specification](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request) (OpenRouter's API is compatible with OpenAI's format)