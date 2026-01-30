In this stage, you'll add support for the `Glob` tool.

### The `Glob` Tool

The `Glob` tool enables the LLM to search for files using a glob pattern. You'll need to advertise this tool in your request and execute it when the LLM requests it.

Here is an example of the `Glob` tool's specification:

```json
{
  "type": "function",
  "function": {
    "name": "Glob",
    "description": "Find files based on glob patterns",
    "parameters": {
      "type": "object",
      "properties": {
        "pattern": {
          "type": "string",
          "description": "The glob pattern to match files against"
        }
      },
      "required": ["pattern"],
      "additionalProperties": false
    }
  }
}
```

To add support for the `Glob` tool:

1. Advertise the `Glob` tool in your request's `tools` array, specifying the function's name, description, and parameters.
2. When you detect `Glob` tool calls in the LLM's response, extract the arguments for each tool call.
3. For each tool call, search for the files using the specified pattern.
4. The result of each tool call should be sent back to the LLM as part of the agent loop (which was implemented in earlier stages).

### Tests

The tester will create the following files in the `app` directory:
  - `test_arithmetic.py` - Contains a buggy assertion for the `add` function
  - `test_geometry.py` - Contains a buggy assertion for the `area_of_square` function
  - `main.py` Contains the correct implementations of these functions.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "Fix all bugs in files in `app` that start with `test`. Respond with `Fixed all bugs`"
```

The tester will verify that:
  - `app/test_arithmetic.py` contains the corrected assertion: `assert add(1, 1) == 2` (changed from `== 3`)
  - `app/test_geometry.py` contains the corrected assertion: `assert area_of_square(5) == 25` (changed from `== 55`)
  - Your program exits with code 0.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names is valid:
  - `Glob`
  - `glob`
  - `GlobPattern`
  - `GlobSearch`, etc.

- The tester will only check the files' contents and exit code, and not the output of your program.
