In this stage, you'll add support for conversational loop, using the results from previous tool calls to inform LLM about subsequent actions.

### The Conversational Loop

A conversational loop enables the LLM to:

1. Make a tool call
2. Receive the tool result
3. Use that result to make another tool call or provide a final answer
4. Continue until the task is complete

This is essential for complex tasks that require multiple steps.

### How the Conversational Loop Works

The loop follows these steps:

1. **Initial request**: Send the user's prompt with tools advertised
2. **Check response**: Examine the LLM's response:
   - If `tool_calls` is present: Execute the tool(s) and send results back
   - If `content` is present and `finish_reason` is `"stop"`: The LLM has provided a final answer - print it and exit
3. **Send tool results**: When tool calls are executed, send the results back to the LLM in a follow-up message
4. **Continue**: Make another API request with the updated message history
5. **Repeat**: Continue until the LLM provides a final answer (no more tool calls)

### Sending Tool Results Back

When you execute a tool call, you need to send the result back to the LLM. Add a message with `role: "tool"` to your messages array:

```json
{
  "model": "anthropic/claude-haiku-4.5",
  "messages": [
    {
      "role": "user",
      "content": "Read the contents of /path/to/master.txt"
    },
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {
          "id": "call_abc123",
          "type": "function",
          "function": {
            "name": "Read",
            "arguments": "{\"file_path\": \"/path/to/master.txt\"}"
          }
        }
      ]
    },
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "<file contents here>"
    }
  ],
  "tools": [...]
}
```

**Key points:**
- `role`: Must be `"tool"`
- `tool_call_id`: Must match the `id` from the tool call you're responding to
- `content`: The result of the tool execution (e.g., file contents for Read, "Success" for Write/Edit, command output for Bash)

### Maintaining Conversation History

Each API request must include the complete conversation history. As the loop progresses, you build up a `messages` array that contains:

1. **Initial user message**: The original prompt
2. **Assistant responses**: Each response from the LLM (with tool calls or content)
3. **Tool result messages**: Each tool execution result you send back

**Example: Building message history across multiple API calls**

**First API request:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Read the contents of /path/to/master.txt"
    }
  ],
  "tools": [...]
}
```

**LLM responds with a tool call:**
```json
{
  "role": "assistant",
  "content": null,
  "tool_calls": [{"id": "call_1", ...}]
}
```

**Second API request (include previous messages + tool result):**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Read the contents of /path/to/master.txt"
    },
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [{"id": "call_1", ...}]
    },
    {
      "role": "tool",
      "tool_call_id": "call_1",
      "content": "/path/to/file1.txt"
    }
  ],
  "tools": [...]
}
```

**LLM responds with another tool call:**
```json
{
  "role": "assistant",
  "content": null,
  "tool_calls": [{"id": "call_2", ...}]
}
```

**Third API request (include all previous messages + new tool result):**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Read the contents of /path/to/master.txt"
    },
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [{"id": "call_1", ...}]
    },
    {
      "role": "tool",
      "tool_call_id": "call_1",
      "content": "/path/to/file1.txt"
    },
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [{"id": "call_2", ...}]
    },
    {
      "role": "tool",
      "tool_call_id": "call_2",
      "content": "file contents here"
    }
  ],
  "tools": [...]
}
```

**Key points:**
- Never remove messages from the history - always append new ones
- Include the assistant's response message (with tool calls) before adding the corresponding tool result
- The order matters: user → assistant → tool → assistant → tool → ...
- Each API request should include the complete history up to that point

### When to Stop

Stop the loop when:
- The response has `finish_reason: "stop"` (not `"tool_calls"`)
- The response has `content` with text (not `null`)
- There are no `tool_calls` in the message

At this point, print the `content` to stdout and exit.

### Tests

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Read the contents of /path/to/master.txt. The file contains another file's full path. Read that file and print its contents. No more. No less. No backticks either."
<contents of the referenced file>
```

- The tester will create multiple files and a `master.txt` file containing the path to one of them
- Your program should read `master.txt`, extract the file path, read that file, and print its contents
- The tester will assert that the output matches the contents of the file referenced in `master.txt`

### Notes

- The LLM may make multiple tool calls in sequence before providing a final answer
- Always check `finish_reason` and the presence of `tool_calls` to determine whether to continue the loop or stop

