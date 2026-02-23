In this stage, you'll implement an agent loop.

### The Agent Loop

So far, your program handles a single interaction: send a prompt to the LLM, get a response, execute one tool if requested, and exit. 

This works for simple tasks, but falls short when the task requires multiple steps (e.g., "read a file and fix any bugs").

For this stage, you'll implement an agent loop that repeatedly sends messages to the model and handles tool calls as needed, until the final result is received. 

Here's how to implement the agent loop:

1. **Initialize the conversation**: You already have an initial conversation history: the `messages` array with the user's prompt. Now you need to store this array so it can persist across iterations, since the loop will continuously append new messages to it:
    ```js
    [
      { "role": "user", "content": "Summarize the README for me." }
    ]
    ```
    
2. **Enter the loop**: Start the loop with the same API request you already have (sending your `messages` and tool specifications to the model). The difference is that this request now sits in a loop, allowing it to run multiple times.
3. **Record the assistant's response**: Whatever message the model returns, add it to your `messages` array. If the model wants to use a tool, the response will contain a `tool_calls` array:
    ```js
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {
          "id": "call_abc123",
          "function": {
            "name": "Read",
            "arguments": "{\"file_path\": \"README.md\"}"
          }
        }
      ]
    }
    ```
     
4. **Execute tool calls**: Check the model's response to see if it's requesting to use any tools. If tool calls are present:
    a. Execute each requested tool (but do not print their result to stdout).
    b. Add each tool call result to your `messages` array. Every tool result must:
        - Have the `role` field set to `"tool"`
        - Reference the corresponding `tool_call_id`
        - Include the tool call result as its `content`
  
    ```js
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "# My Project\n\nChemical expiry period: 6 months"
    }
    ```
    
5. **Repeat until complete**: Continue the loop until the model responds without requesting any tools (when `tool_calls` is missing or empty). At this point, print the final message `content` to stdout and exit.

### Tests

The tester will create a Python project with:
- `README.md`
- Two Python files in `app/` with randomized names

The tester will then execute your program like this:

```bash
$ ./your_program.sh -p "Use README.md to determine the chemical expiry period in months. Number only."
<expiry period in months>
```

The tester will verify that:
- The output is the correct expiry period
- Your program exits with exit code `0`

### Notes

- Do not print raw file contents when executing the Read tool. This differs from the behavior in the “Execute the read tool” stage.
- You can print intermediate debugging information to stderr. Print to stdout only when the final result is ready to be printed.
- You can also use `finish_reason: "stop"` from the first response choice as a signal to stop the loop.