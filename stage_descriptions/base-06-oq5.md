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
3. Run the given command in the bash and print the result.

### Tests

- The tester will create some random files in a directory.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "<Prompt specifying to print the names of all files inside the directory in a sorted alphabetical order>"
file1.txt
file2.txt
file3.txt
file4.txt
```
- The tester will assert that your program outputs the file names, one per line, in an alphabetical order.

### Notes

- The tester will only perform end-to-end tests. You are free to choose the name of the tool and its arguments. For example, any of the following names are valid:
  - `Bash`
  - `bash`
  - `RunBashCommand`
  - `run_bash_command`, etc.

- You can directly print the tool call's result without sending it back to the LLM. We'll get to implementing the conversational loop in the later stages.