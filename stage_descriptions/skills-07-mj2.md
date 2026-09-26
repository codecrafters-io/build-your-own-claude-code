In this stage, you'll add support for skills that run in a subagent.

### Subagents

A skill can ask to be handled by a [subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) instead of by the main agent you've been building, by setting `context: fork` in its frontmatter.

A subagent is a second run of your agent loop with a conversation of its own. It takes the skill's body as its prompt, works through it, and hands back a single answer.

```markdown
---
name: apple
description: Use this skill when the user asks about the on-call rotation.
context: fork
---

Respond with exactly one word: blueberry
```

By adding `context:fork`, apple's body goes to the subagent. It has a new conversation stack and only the answer comes back to the main conversation. 

### What your program does

For `./your_program.sh -p "Who is on the on-call rotation right now?"`:

1. Discover the skills and build the catalog for the system prompt, as before.
2. The model matches the question against `apple` and calls the Skill tool, the same way it did in previous stages.
3. Check `context` before returning the body. `apple` asks for a subagent, so its body doesn't go into the main conversation. Start a **separate** list of messages holding only that body, and run your agent loop over it.
4. Return the subagent's answer as the tool's result. For the above skill, that result can be:
  ```
   Skill apple ran in a separate context and returned: blueberry
  ```
5. Run your agent loop over the main conversation, and print its answer.

Steps 3 and 4 happen inside the Skill tool handler you wrote in previous stages. Until now it returned a body for every name it recognised, and a forked skill is the one case where it returns something else.

Steps 3 and 5 are the same loop. A subagent is that loop called again with a different list of messages, so most of this stage is pulling the loop out of wherever it currently lives.

### The subagent's messages

The subagent's conversation starts empty. It receives the skill's body and nothing else, so the question that triggered it never reaches it:

```js
[
  { "role": "user", "content": "Respond with exactly one word: blueberry" }
]
```

Say it answers `blueberry`. That word is the only thing that comes out of the subagent. Whatever your program wraps around that word on the way back, as step 4 does, is your own framing rather than something the subagent returned.

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
- Claude Code also supports an [agent field](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) that picks which type of subagent handles the skill. We won't be handling different subagent types in this extension.

