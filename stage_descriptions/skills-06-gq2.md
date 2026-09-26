In this stage, you'll add support for the model choosing a skill on its own.

### Model-invoked skills

Every skill so far has been triggered by the user typing `/name`. For this stage, your [agent will decide](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill) when to invoke the skill. 

The user describes a task in plain language, the model compares it against the descriptions already in its context, and loads the one that fits.

The descriptions are already there from earlier stages. What's missing is a way for the model to ask for a body.

### Giving the model a way in

The `Skill` tool enables the LLM to invoke a skill. Like with the `Read` , `Write` and `Bash`tools, you need to advertise the `Skill` tool in your request and execute it when the model requests it.

Here's the tool specification: 

```json
{
    "type": "function",
    "function": {
      "name": "Skill",
      "description": "Load a skill's instructions into the conversation",
      "parameters": {
        "type": "object",
        "required": ["name"],
        "properties": {
          "name": { "type": "string", "description": "The name of the skill to use" },
          "args": { "type": "string", "description": "Optional arguments for the skill" }
        }
      }
    }
  }
```

After adding it to the list of tools, update the system prompt to point to this tool:

```
You have access to the following skills:

- apple: Use this skill when the user asks for the database migration status.
- grape: Use this skill when the user asks to format source code.

If a skill matches the user's request, call the Skill tool with its name
and follow the instructions it returns.
```

Your program looks the name up among the skills you discovered and returns that skill's body as the tool result. 

```bash
$ ./your_program.sh -p "What is the database migration status?"
```

The model matches the request against `apple`'s description, calls `Skill` tool with `"apple"`, and follows the body it gets back.

Notice what makes this work: the descriptions say **when** to use the skill, not just what it does. A description of "Database utilities" for the skill `apple` gives the model nothing to match against.

### Tests

The tester will create two skills with clearly different descriptions, then send a request that matches exactly one of them without naming it:

```bash
$ ./your_program.sh -p "What is the database migration status?"
blueberry
```

The tester will verify that:

- Your program outputs the word from the matching skill's body
- Your program exits with exit code `0`



### Notes

- The second skill is a decoy. Its description won't match the request, and its body contains a different word, so loading both skills will fail this stage.

