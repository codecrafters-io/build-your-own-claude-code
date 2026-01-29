In this stage, you'll add support for advertising the `Read` tool in the request.

### Tools

Tools are functions that an LLM can request to perform specific actions, like reading files or running commands.

By default, LLMs do not have access to a user's environment (e.g., their filesystem or terminal). Claude Code uses several [tools](https://code.claude.com/docs/en/settings#tools-available-to-claude) (such as `Read`, `Write`, and `Bash`) that enable the LLM to understand and modify the user's codebase.

### Advertising Tools

To make tools available to the LLM, you need to advertise them in your API request. This allows the model to request these tools from your program when needed.

For this stage, you only need to advertise the `Read` tool.

### The `Read` Tool

The `Read` tool lets the LLM request a file's contents.

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

This structure consists of the following fields:
- `type`: The type of tool (always `"function"` for tools)
- `function`: Contains the function definition
  - `name`: The name of the function (e.g., "Read")
  - `description`: Explains the function's purpose and helps the LLM determine when to use it.
  - `parameters`: A JSON schema describing the function's parameters
    - `properties`: Defines each parameter (in this case, just `file_path`)
    - `required`: Lists which parameters are mandatory
   
You can advertise the `Read` tool by including its specification in the `tools` array of your API request.

### Tests

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "How many tools are available to you in this request? Number only."
1
```

The tester will verify that:
- Your program outputs a positive number
- Your program exits with exit code `0`

### Notes

- You can choose any reasonable name for the `Read` tool. The tester will only perform end-to-end tests by checking the LLM's response. For example, any of the following names is valid:
  - `Read`
  - `read`
  - `read_file`
  - `ReadFile`, etc.
- For this stage, you only need to advertise the `Read` tool's availability in the request. We'll handle tool calls in later stages.
- See the [OpenRouter API Specification for Tools](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request#request.body.tools) for the full API documentation on how to include tools in your request.
