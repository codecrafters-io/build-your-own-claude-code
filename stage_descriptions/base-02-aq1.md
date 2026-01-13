In this stage, you'll add support for advertising the `Read` tool in the request.

### Advertising Tools

Tools are functions that the LLM can request Claude Code to call to perform specific actions. By advertising tools in the request, Claude Code tells the LLM what capabilities are available to it.

Claude Code has access to many powerful tools including Read, Write, Edit, Bash, Grep, and more (see [Tools available to Claude Code](https://code.claude.com/docs/en/settings#tools-available-to-claude)).

For this stage, you'll only need to advertise the `Read` tool, which allows the LLM to ask Claude Code to read file contents.

Here is an example of the `Read` tool's specification:

```json
{
  "type": "function",
  "function": {
    "name": "Read",
    "description": "Read and return the contents of a file",
    "parameters": {
      "type": "object",
      "properties": {
        "file_path": {
          "type": "string",
          "description": "The path to the file to read"
        }
      },
      "required": ["file_path"]
    }
  }
}
```

The descriptions of the fields are:

- `type`: The type of tool (always `function` for tools)
- `function`: The function definition containing:
  - `name`: The name of the function (e.g., "Read")
  - `description`: A description of what the function does
  - `parameters`: A JSON schema describing the function's parameters

### Tests

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "<Prompt asking to print the count of available tools in the request>"
1
```

The tester will assert that the output is a positive number.

### Notes

- You are free to choose the name of the tool. The tester will only perform end-to-end tests, supplying the prompt and asserting the output. For example, any of the following names are valid:
  - `Read`
  - `read`
  - `read_file`
  - `ReadFile`, etc.

- In this stage, you'll only need to advertise the availability of the `Read` tool in your request. We'll get to tool call execution in the next stage.

- [OpenRouter API Specification for Tools](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request#request.body.tools)