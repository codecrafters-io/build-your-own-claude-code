In this stage, you'll add support for skills that run in a subagent.

### Subagents

A skill can ask to be handled by a [subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) instead of by the main agent you've been building, by setting `context: fork` in its frontmatter.

A subagent is a second run of your agent loop with a conversation of its own. It takes the skill's body as its prompt, works through it, and hands back a single answer. 

Let's say your workspace holds two skills. `grape` is an ordinary one:

```markdown
---
name: grape
description: Summarizes recent incidents for the payments team.
---

Add this exact line to your response: cherry
```

and `apple` asks for a subagent:

```markdown
---
name: apple
description: Reports the deploy target for the apple service.
context: fork
---

Respond with exactly one word: blueberry
```

Invoking `grape` works as it always has: its body joins the main conversation. Invoking `apple` doesn't, its body goes to the subagent instead.

### What your program does

For `./your_program.sh -p "/apple"`:

1. Discover the skills and build the catalog for the system prompt, as before.
2. Expand the invocation, as before, but this time look at the skill's `context` field.
3. `apple` asks for a subagent, so its body doesn't go into the main conversation. Start a **separate** list of messages holding only that body, and run your agent loop over it.
4. Add the subagent's answer to the main conversation as the skill's result.
5. Run your agent loop over the main conversation, and print its answer.

Steps 3 and 5 are the same loop. A subagent is that loop called again with a different list of messages, so most of this stage is pulling the loop out of wherever it currently lives.

### Two requests

The first request is the subagent's:

```js
[
  { "role": "user", "content": "Respond with exactly one word: blueberry" }
]
```

Say it answers `blueberry`. The second is the main conversation, told what the skill returned:

```js
[
  { "role": "system", "content": "You have access to the following skills:\n\n- apple: Reports the deploy target...\n- grape: Summarizes recent incidents..." },
  { "role": "user", "content": "The /apple skill ran in a subagent and returned:\n\nblueberry" }
]
```

Its response is what your program prints.

### Tests

The tester will create two skills with random names, one of them asking for a subagent, and invoke that one. Its body asks for a random word:

```bash
$ ./your_program.sh -p "/apple"
The apple skill returned blueberry.
```

The other skill is seeded but never invoked, so its name reaches the model only through the catalog.

The tester will watch the requests your program sends, and verify that:

- One of them carries the skill's instructions **without** the skill catalog
- One of them carries **both** the catalog and the subagent's answer
- The subagent's answer appears in your program's output



### Notes

- A skill that asks for a subagent ends a stacking run, so it's never expanded alongside another. You only need to handle it as a lone invocation.
- Your subagent is your agent loop, so the model can still call tools inside it.
- [Claude Code](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) also supports `agent` field picks which type of subagent handles the skill. We won't be handling different subagent types in this extension. 

