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
2. When you detect a `Write` tool call in the LLM's response, extract the arguments.
3. Create the file if it does not exist, or overwrite the file if it already exists, with the specified content.

### Tests

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "<Prompt specifing a random contents and a random file path to write to>"
```

- The tester will assert that:
  - If the file doesn't exist, the file is created with the specified content.
  - If the file exists, the original contents of the file is over-written with the specified content.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Write`
  - `write`
  - `write_file`
  - `WriteFile`, etc.

- The tester will only check the existence of the file with its contents, and not the output of your program. You are free to set the return value of the `Write` tool be whatever you deem fit.

- You don't need to send the tool result back to the LLM yet. We'll implement the conversational loop in later stages.