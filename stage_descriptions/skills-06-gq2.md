In this stage, you'll add support for the model choosing a skill on its own.

### Model-invoked skills

Every skill so far has been triggered by the user typing `/name`. That's the easy case — your program is told exactly which body to load.

The more useful case is [the model deciding for itself](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill). The user describes a task in plain language, the model compares it against the descriptions already in its context, and loads the one that fits.

The descriptions are already there from earlier stages. What's missing is a way for the model to ask for a body.

### Giving the model a way in

The model can read files, so the simplest approach is to tell it where the bodies are and let it use the `Read` tool. Extend your system prompt:

```
You have access to the following skills:

- apple: Use this skill when the user asks for the database migration status.
- grape: Use this skill when the user asks to format source code.

If a skill matches the user's request, read .claude/skills/<name>/SKILL.md
with the Read tool and follow the instructions inside before answering.
```

Now a prompt that never mentions a skill by name can still trigger one:

```bash
$ ./your_program.sh -p "What is the database migration status?"
```

The model matches the request against `apple`'s description, reads `.claude/skills/apple/SKILL.md`, and follows it.

Notice what makes this work: the descriptions say **when** to use the skill, not just what it does. A description of "Database utilities" gives the model nothing to match against.

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
- Explicit `/name` invocation must keep working. The two paths coexist.
- This stage depends on the model's judgment, so it is the most sensitive one in this extension. If it fails, check your system prompt wording before assuming your code is wrong.
