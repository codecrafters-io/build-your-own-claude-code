In this stage, you'll add support for the `Glob` tool.

### The `Glob` Tool

The `Glob` tool enables the LLM to search for files using glob patterns (like `*.py` or `test_*.txt`). This is useful when the LLM needs to find files that match a certain pattern without knowing their exact names.

You need to advertise the `Glob` tool in your request and execute it when the LLM requests it.

Here's the tool specification:
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
      "required": ["pattern"]
    }
  }
}
```

### Executing the `Glob` Tool

When the LLM requests a `Glob` tool call:

1. Parse the arguments to extract the `pattern`
2. Search for files matching the pattern using your language's glob functionality (e.g., `glob.glob()` in Python, `fs.glob()` in Node.js)
3. Return the list of matching file paths as the tool message

### Tests

The tester will create the following files in the `app/` directory:
- `test_arithmetic.py` with a buggy assertion: `assert add(1, 1) == 3`
- `test_geometry.py` with a buggy assertion: `assert area_of_square(5) == 55`
- `main.py` with correct implementations

The tester will then execute your program like this:

```bash
$ ./your_program.sh -p "Fix all bugs in files in `app` that start with `test`. Respond with `Fixed all bugs`"
```

The tester will verify that:
  - `app/test_arithmetic.py` contains the corrected assertion: `assert add(1, 1) == 2` (changed from `== 3`)
  - `app/test_geometry.py` contains the corrected assertion: `assert area_of_square(5) == 25` (changed from `== 55`)
  - Your program exits with code `0`

### Notes

- You can choose any reasonable name for the Glob tool (e.g., `Glob`, `glob`, `GlobPattern`, `GlobSearch`).
- The tester will only check the files' contents and exit code, and not the output of your program.
- Most programming languages have built-in glob support or standard libraries that provide it.
