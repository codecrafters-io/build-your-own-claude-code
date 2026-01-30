In this stage, you'll add support for the `Bash` tool.

### The `Bash` Tool

The `Bash` tool enables the LLM to run shell commands. This is the most powerful tool because it gives the LLM direct access to the command line to perform actions like deleting files, creating directories, or running scripts.

You'll need to advertise the `Bash` tool in your request and execute it when the LLM requests it.

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

### Executing the `Bash` Tool

When the LLM requests a `Bash` tool call:

1. Parse the arguments to extract the `command`
2. Execute the command using your language's shell execution capabilities (e.g., `subprocess.run()` in Python, `child_process.exec()` in Node.js)
3. Capture both stdout and stderr from the command
4. Return the command output (or an error message if it failed) to the LLM as a tool message

For example, if the command is `rm README_old.md`, execute it and return the result (which will be empty if successful).

### Tests

The tester will create three files:
  - `app/main.js` - Main project file
  - `README.md` - The current readme file
  - `README_old.md` - An old readme file

The tester will then execute your program like this:

```bash
$ ./your_program.sh -p "Delete the old readme file. Always respond with `Deleted README_old.md`"
Deleted README_old.md
```

The tester will verify that:
  - `README_old.md` has been deleted (no longer exists)
  - `app/main.js` remains intact with its original contents
  - `README.md` remains intact with its original contents
  - Your program exits with code `0`

### Notes

- You can choose any reasonable name for the Bash tool (e.g., `Bash`, `bash`, `RunBashCommand`, `run_bash_command`).
- The result of the `Bash` tool call should be sent back to the LLM as part of the agent loop.
- Make sure to execute the command in the same directory as your program, not in a temporary or different working directory.
