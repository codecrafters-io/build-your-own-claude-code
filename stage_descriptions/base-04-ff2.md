In this stage, you'll implement an agent loop.

### The Agent Loop

So far, your program handles a single interaction: send a prompt to the model, get a response, execute one tool if requested, and exit. 

This works for simple tasks, but falls short when the task requires multiple steps (e.g., "read a file and fix any bugs").

For this stage, you'll implement an agent loop that repeatedly sends messages to the LLM and handles tool calls as needed, until the final result is received. 

Here's how to implement the agent loop:

1. **Initialize the conversation**: You already have an initial conversation history: the `messages` array with the user's prompt. Now you need to store this array so it can persist across iterations, since the loop will continuously append new messages to it:
   
    ```json
    [
      { "role": "system", "content": "You are a helpful coding assistant..." },
      { "role": "user", "content": "What files are in this project?" }
    ]
    ```

2. **Enter the loop**: Start the loop with the same API request you already have (sending your `messages` and tool specifications to the LLM). The difference is that this request now sits in a loop, allowing it to run multiple times.
3. **Record the assistant's response**: Whatever message the LLM returns, add it to your `messages` array. If the model wants to use a tool, the response will contain a `tool_calls` array:

   ```json
    {
      "role": "assistant",
      "content": null,
      "tool_calls": [
        {
          "id": "call_abc123",
          "function": {
            "name": "Glob",
            "arguments": "{\"pattern\": \"*\"}"
          }
        }
      ]
    }
    ```
   
4. **Check for tool calls**: Check the LLM's response to see if it's requesting to use any tools. If there are tool calls, execute each requested tool, then add their result to your `messages` array. Each tool result must have a `role` of `"tool"`, reference its corresponding `tool_call_id`, and contain the output of the tool call as its `content`:

   ```json
    {
      "role": "tool",
      "tool_call_id": "call_abc123",
      "content": "main.py\nREADME.md\ntest.py"
    }
    ```
   
5. **Repeat until complete**: Continue the loop until the LLM responds without requesting any tools (when `tool_calls` is missing or empty). At this point, print the final message `content` to stdout and exit.

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

- You can also use `finish_reason: "stop"` from the first response choice as a signal to stop the loop.
