In this stage, you'll add support for the `Write` tool.

### The `Write` Tool

The `Write` tool enables the LLM to write content to files. Like the `Read` tool, you need to advertise it in your request and execute it when the LLM requests it.

Here's the tool specification:
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

### Executing the Write Tool

When the LLM requests a `Write` tool call:

1. Parse the arguments to extract the `file_path` and `content`
2. Write the content to the file at the specified path:
   - If the file doesn't exist, create it
   - If the file exists, overwrite it with the new content
3. Append the result to messages as a tool message (just like with `Read`)

### Tests

The tester will create the following:
- `README.md` with instructions
- `app/` directory for the project

It will then execute your program like this:
```bash
$ ./your_program.sh -p "Read README.md and create the required file. File should have 1 line. Reply with 'Created the file'"
Created the file
```

The tester will verify that:
- The required file is created with the correct contents
- Your program exits with exit code `0`

### Notes

- You can choose any reasonable name for the Write tool (e.g., `Write`, `write`, `write_file`, `WriteFile`).
