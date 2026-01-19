In this stage, you'll add support for the agent loop.

### The Agent Loop

The agent loop repeatedly sends messages to the LLM and handles tool calls as needed, until the final result is received. When the LLM decides to use tools, the response message will contain a `tool_calls` array. All the tool calls listed in the array should be executed, and their results should be sent back to the LLM.

Here is a pseudocode example of the agent loop:

```python
def agent_loop(initial_prompt):
    messages = [{"role": "user", "content": initial_prompt}]
    
    while True:
        response = send_to_llm(messages)
        llm_response = response["message"]
        messages.append(llm_response)
        
        if llm_response.has_tool_calls():
            for tool_call in llm_response.tool_calls:
                tool_result = execute_tool(tool_call)
                messages.append({
                    "role": "tool",
                    "content": tool_result,
                    "tool_call_id": tool_call.id
                })
        else:
            return llm_response.content
```

When a tool call is executed, the result is sent back to the LLM by adding a message with `role: "tool"` to the messages array:

```json
{
  // Conversation History - Serves as a context for the LLM
  "messages": [
    // First prompt - Appended to the 'messages' array
    {
      "role": "user",
      "content": "Read the contents of /path/to/file1.txt and /path/to/file2.txt"
    },
    // The assistant (LLM) requested multiple tool calls
    // This is also appended to the 'messages' array
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {
          "id": "call_abc123",
          "type": "function",
          "function": {
            "name": "Read",
            "arguments": "{\"file_path\": \"/path/to/file1.txt\"}"
          }
        },
        {
          "id": "call_xyz789",
          "type": "function",
          "function": {
            "name": "Read",
            "arguments": "{\"file_path\": \"/path/to/file2.txt\"}"
          }
        }
      ]
    },
    // Each tool call result must be appended as a separate message
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "<file1 contents here>"
    },
    {
      "role": "tool",
      "tool_call_id": "call_xyz789",
      "content": "<file2 contents here>"
    }
  ],
  "tools": [...]
}
```

Here are the descriptions of the fields:
- `role`: Must be `"tool"`
- `tool_call_id`: Must match the `id` from the tool call you're responding to
- `content`: The result of the tool execution (e.g., file contents for Read)

Messages should be appended to the conversation history (e.g., user prompt → assistant response → tool result → assistant response → tool result → ...). Stop the loop when the response has `finish_reason: "stop"` and there are no `tool_calls`. At this point, print the `content` to stdout and exit.

### Tests

- The tester will create a file `manifest.txt` containing two file paths, one per line.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Read manifest.txt and print ONLY the contents of both files in order they appear in manifest. No backticks either."
<contents of both files in order>
```

- Read `manifest.txt` to get the file paths.
- Read both files and print their contents in the order they appear in the manifest.

### Notes

- Always check `finish_reason` and the presence of `tool_calls` to determine whether to continue the loop or stop.
