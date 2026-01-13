In this stage, you'll add support for the conversational loop.

### The Conversational Loop

The conversational loop repeatedly sends messages to the LLM and handles tool calls as needed, until the final result is received. Here is a pseudocode example of the conversational loop.

```python
def conversational_loop(initial_prompt: str) -> str:
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
      "content": "Read the contents of /path/to/master.txt"
    },
    // The assistant (LLM) requested a tool call after the first request (which contained only prompt)
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
            "arguments": "{\"file_path\": \"/path/to/master.txt\"}"
          }
        }
      ]
    },
    // The tool call resulted in a result, which must be appended to the 'messages' array
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "<file contents here>"
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

- The tester will create multiple files, each with random contents.
- The tester will create two index files. These files will each contain the path of one randomly selected file created earlier.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Read the contents of /path/to/index1.txt and /path/to/index2.txt. Each file contains a file path. Read those files and print their contents, one after another."
<contents of the referenced files>
```

- Extract the file names from the first two files.
- Print the contents of the files whose names were extracted, one after another.

### Notes

- Always check `finish_reason` and the presence of `tool_calls` to determine whether to continue the loop or stop.
