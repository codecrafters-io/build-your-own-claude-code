In this stage, you'll add support for detecting tool calls and executing the
`Read` tool call.

### Tool Calls

When the LLM decides to use a tool, the response message will contain a
`tool_calls` array.

Here's what the response looks like:

```js
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

The key fields you need to handle are:

- `choices`: The list of generated responses. For this challenge, there will
  always be exactly **one** choice.
- `tool_calls`: The array of tool calls to make
  - `id`: A unique identifier for the tool call
  - `type`: The type of tool call (always `"function"` for tools)
  - `function`: Contains the function details:
    - `name`: The name of the function to call (e.g., `"Read"`)
    - `arguments`: A JSON string containing the function parameters

For this stage, you'll execute a single `Read` tool call.

### Executing the `Read` Tool

When you detect a `tool_calls` array in the response:

1. **Extract the tool call**: Get the message from the first choice, then
   extract the first tool call from the `tool_calls` array.
2. **Parse the function name**: Read the function name to determine which tool
   to execute.
3. **Parse the arguments**: Parse the function arguments as a JSON string to get
   the parameters.
4. **Execute the tool**: Your program must perform the action requested. For the
   `Read` tool, use your language's file system library to read the file at the
   requested `file_path`.
5. **Output the result**: Print the raw file contents to stdout.

### Tests

The tester will create a file (e.g., `apple.py`) and execute your program like
this:

```bash
$ ./your_program.sh -p "What is the content of apple.py? Print exact file contents without backticks."
<file contents>
```

The tester will verify that:

- The output matches the exact contents of the file
- Your program exits with code `0`

### Notes

- For this stage, you only need to print the result of the first tool call.
  We'll get to handling multiple tool calls in later stages.
- You don't need to send the tool call result back to the model. We'll implement
  the full agent loop (sending results back and continuing the conversation) in
  later stages.
- For a complete reference of the response structure, see the
  [OpenRouter API Specification](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request).
