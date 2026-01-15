In this stage, you'll add support for the `Bash` tool.

### The Bash Tool

The Bash tool enables the LLM to run shell commands. You'll need to advertise this tool in your request and implement its execution when the LLM requests it.

Here is an example of the `Bash` tool's specification:

```json
{
  "type": "function",
  "function": {
    "name": "Bash",
    "description": "Execute a shell command",
    "parameters": {
      "type": "object",
      "required": ["command"],
      "properties": {
        "command": {
          "type": "string",
          "description": "The command to execute"
        }
      }
    }
  }
}
```

To add support for the `Bash` tool:

1. Advertise the `Bash` tool in your request's `tools` array, specifying the function's name, description, and parameters.
2. When you detect a `Bash` tool call in the LLM's response, extract the arguments.
3. Run the given command in bash and append the result of the tool call in the subsequent request.

### Tests

- The tester will create multiple files inside a directory `/path/to/dir`.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "List all the JSON files inside `/path/to/dir` one per line. List only basenames in sorted alphabetical order. Nothing else. No backticks either."

```

- The tester will assert that the output consists of the basenames of all JSON files inside `/path/to/dir`, sorted alphabetically, with one filename per line.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Bash`
  - `bash`
  - `RunBashCommand`
  - `run_bash_command`, etc.

- The result of the Bash tool call should be sent back to the LLM as part of the conversational loop (which was implemented in stage 5).