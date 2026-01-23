In this stage, you'll add support for the `Write` tool.

### The `Write` Tool

The `Write` tool enables the LLM to write content to files. You'll need to advertise this tool in your request and implement its execution when the LLM requests it.

Here is an example of the `Write` tool's specification:

```json
{
  "type": "function",
  "function": {
    "name": "Write",
    "description": "Write content to a file",
    "parameters": {
      "type": "object",
      "required": ["file_path", "content"],
      "properties": {
        "file_path": {
          "type": "string",
          "description": "The path of the file to write to"
        },
        "content": {
          "type": "string",
          "description": "The content to write to the file"
        }
      }
    }
  }
}
```

To add support for the `Write` tool:

1. Advertise the `Write` tool in your request's `tools` array, specifying the function's name, description, and parameters.
2. When you detect `Write` tool calls in the LLM's response, extract the arguments for each tool call.
3. For each tool call, create the file if it does not exist, or overwrite the file if it already exists, with the specified content.
4. The result of each tool call should be sent back to the LLM as part of the agent loop (which was implemented in earlier stages)

### Tests

The tester will create a simple python project structured as follows:

- `README.md`
- `app/`

The `README.md` will contain what the project should do and the file it should contain.

The tester will then run your program like this:

```bash
$ ./your_program.sh -p "Read README.md and create the required file. File should have 1 line. Reply with `Created the file`"
```

The tester will assert that:
  - The required file is created
  - Your program responds with `Created the file` and exits with code 0.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Write`
  - `write`
  - `write_file`
  - `WriteFile`, etc.