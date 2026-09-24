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
description: Use this skill when the user asks about the on-call rotation.
context: fork
---

Respond with exactly one word: blueberry
```

When the model reaches for `grape`, its body joins the main conversation. When it reaches for `apple`, its body goes to the subagent instead.

### What your program does

For `./your_program.sh -p "Who is on the on-call rotation right now?"`:

1. Discover the skills and build the catalog for the system prompt, as before.
2. The model matches the question against `apple` and asks for its instructions, as in earlier stages.
3. `apple` asks for a subagent, so its body doesn't go into the main conversation. Start a **separate** list of messages holding only that body, and run your agent loop over it.
4. Hand the subagent's answer back to the main conversation as the skill's result.
5. Run your agent loop over the main conversation, and print its answer.

Steps 3 and 5 are the same loop. A subagent is that loop called again with a different list of messages, so most of this stage is pulling the loop out of wherever it currently lives.

### The subagent's messages

The subagent's conversation starts empty. It receives the skill's body and nothing else, so the question that triggered it never reaches it:

```js
[
  { "role": "user", "content": "Respond with exactly one word: blueberry" }
]
```

Say it answers `blueberry`. That one word is all that travels back to the main conversation, which is where the question has been all along.

### Tests

The tester will create two skills with random names, one of them asking for a subagent, and ask a question that matches it. Its body asks for a random word:

```bash
$ ./your_program.sh -p "Who is on the on-call rotation right now?"
The on-call engineer is blueberry.
```

The other skill is seeded but never matched, so the catalog holds more than the skill under test.

The tester will watch the requests your program sends, and verify that:

- One of them carries the skill's instructions **without** the question that triggered them
- The subagent's answer appears in your program's output



### Notes

- A skill that asks for a subagent ends a stacking run, so it's never expanded alongside another.
- Your subagent is your agent loop, so the model can still call tools inside it. Claude Code usually runs the subagent in the background, but with `-p` it always waits, so you can run it inline.
- Claude Code also supports an [`agent` field](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) that picks which type of subagent handles the skill. We won't be handling different subagent types in this extension.

