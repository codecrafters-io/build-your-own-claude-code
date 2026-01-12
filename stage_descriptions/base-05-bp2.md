In this stage, you'll add support for the `Edit` tool.

### The `Edit` Tool

The `Edit` tool enables the LLM to modify files by replacing text. You'll need to advertise this tool in your request and implement its execution when the LLM requests it.

Here is an example of the `Edit` tool's specification:

```json
{
  "type": "function",
  "function": {
    "name": "Edit",
    "description": "Replace a string inside a file",
    "parameters": {
      "type": "object",
      "required": ["file_path", "old_string", "new_string"],
      "properties": {
        "file_path": {
          "type": "string",
          "description": "The path to the file to modify"
        },
        "old_string": {
          "type": "string",
          "description": "The text to replace"
        },
        "new_string": {
          "type": "string",
          "description": "The text to replace it with (must be different from old_string)"
        }
      }
    }
  }
}
```

To add support for the `Edit` tool:

1. Advertise the `Edit` tool in your request's `tools` array, specifying the function's name, description, and parameters.
2. When you detect a `Edit` tool call in the LLM's response, extract the arguments.
3. In the given file, replace the first occurence of the `old_string` with the `new_string`. 


### Tests

- The tester will create a file with random content

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "<Prompt specifying the file path, old string and the new string to replace with>"
```

- The tester will assert that the file was modified correctly.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Edit`
  - `edit_string`
  - `replace_string`
  - `Replace`, etc.

- The tester will only check if the `old_string` was replaced with the `new_string`. You are free to set the return value of the `Edit` tool be whatever you deem fit.

- You don't need to send the tool result back to the LLM yet. We'll implement the conversational loop in later stages.