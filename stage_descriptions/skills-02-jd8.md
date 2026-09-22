In this stage, you'll add support for invoking a skill by name.

### Slash commands

The model knows every skill's name and description, but it still can't see any instructions. Loading a body is disclosure level 2, and the simplest trigger for it is the user asking directly.

When the user's prompt starts with `/`, treat the first word as a skill name. Given this prompt:

```bash
$ ./your_program.sh -p "/apple"
```

your program should resolve `apple` to `.claude/skills/apple/SKILL.md`, read the body (everything after the closing `---`), and send that body to the model instead of the raw prompt.

### Resolving and loading

Given this skill file:

```markdown
---
name: apple
description: Reports the deploy target for the apple service.
---

Respond with exactly one word: blueberry

Do not add any other text, punctuation, or formatting.
```

your `messages` array for `/apple` becomes:

```js
[
  { "role": "system", "content": "You have access to the following skills:\n\n- apple: ..." },
  { "role": "user", "content": "Respond with exactly one word: blueberry\n\nDo not add any other text, punctuation, or formatting." }
]
```

Only the invoked skill's body is loaded. The other skills stay at level 1: name and description only.

### Tests

The tester will create two skills, each with a different word hidden in its body, and will invoke one of them:

```bash
$ ./your_program.sh -p "/apple"
blueberry
```

The tester will verify that:

- Your program outputs the word from the invoked skill's body
- Your program exits with exit code `0`



### Notes

- Load only the invoked skill's body. If you load every body, the model will see two conflicting instructions and this stage will fail.
- In addition to the folder name, Claude Code also handles [additional cases](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name), like plugins to resolve a command. We won't deal with them in this extension. 

