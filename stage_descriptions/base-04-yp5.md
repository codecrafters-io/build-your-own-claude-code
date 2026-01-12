In this stage, you'll add support for handling multiple tool calls.

### Executing Multiple `Read` Calls

When the LLM decides to use a tool, the response message will contain a `tool_calls` array.

In this stage, you should execute all the tool calls listed in the array and print each of their results one by one.

### Tests

The tester will create multiple files.

The tester will execute your program like this:

```bash
$ ./your_program.sh -p "<Prompt asking the LLM to print the contents of multiple files, one after another>"
```

- The tester will assert that the output matches the exact contents of the specified files, concatenated.

### Notes

- For this stage, you only need to print the result of the tool call. You don't need to send the result back to the LLM. We'll get to implementing the conversational loop in the later stages.

- [OpenRouter API Specification](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request) (OpenRouter's API is compatible with OpenAI's format)