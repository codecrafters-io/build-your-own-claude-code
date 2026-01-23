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
2. When you detect `Edit` tool calls in the LLM's response, extract the arguments for each tool call.
3. For each tool call, in the given file, replace the first occurrence of the `old_string` with the `new_string`.
4. The result of each tool call should be sent back to the LLM as part of the agent loop (which was implemented in stage 5)

### Tests

The tester will create two Python test files in the `app` directory:
  - `app/test_arithmetic.py` - contains a buggy assertion for the `add` function
  - `app/test_geometry.py` - contains a buggy assertion for the `area_of_square` function
  - `app/main.py` containing the correct implementations of these functions.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Fix all bugs in files in `app` that start with `test`. Respond with `Fixed all bugs`"
```

The tester will assert that:
  - `app/test_arithmetic.py` contains the corrected assertion: `assert add(1, 1) == 2` (changed from `== 3`)
  - `app/test_geometry.py` contains the corrected assertion: `assert area_of_square(5) == 25` (changed from `== 55`)
  - Your program responds with `Fixed all bugs` and exits with code 0.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Edit`
  - `edit_string`
  - `replace_string`
  - `Replace`, etc.

- The tester will only check if the `old_string` was replaced with the `new_string` in each file. You are free to set the return value of the `Edit` tool to be whatever you deem fit.