In this stage, you'll add support for stacking multiple skills in one prompt.

### Stacking

So far a prompt has invoked one skill. Claude Code also lets you [stack several](https://code.claude.com/docs/en/skills#pass-arguments-to-skills) at the start of one message:

```bash
$ ./your_program.sh -p "/apple /grape 4127"
```

When this is invoked, both the skill bodies of `apple` and `grape` are loaded, and the trailing text `4127` reaches each of them as `$ARGUMENTS`.

### Where the names stop

Expansion runs from the start of the prompt. Every token that names a skill is expanded, and the first token that doesn't ends the run. That token and everything after it become the argument text for *every* skill you expanded.


| Prompt               | Expanded         | `$ARGUMENTS` for each |
| -------------------- | ---------------- | --------------------- |
| `/apple /grape 4127` | `apple`, `grape` | `4127`                |
| `/apple 4127 /grape` | `apple`          | `4127 /grape`         |
| `/apple /pear 4127`  | `apple`          | `/pear 4127`          |


The last row assumes no skill named `pear` exists, so `/pear` ends expansion and stays in the argument text.

### Building the messages

Given these two skills:

```markdown
---
name: apple
description: Reports the deploy target for the apple service.
---

Add this exact line to your response: blueberry-$ARGUMENTS
```

```markdown
---
name: grape
description: Summarizes recent incidents for the payments team.
---

Add this exact line to your response: cherry-$ARGUMENTS
```

your `messages` array for `/apple /grape 4127` becomes:

```js
[
  { "role": "system", "content": "You have access to the following skills:\n\n- apple: ..." },
  { "role": "user", "content": "Add this exact line to your response: blueberry-4127" },
  { "role": "user", "content": "Add this exact line to your response: cherry-4127" }
]
```

Each body is substituted separately, with the same argument text.

### Tests

The tester will create three skills, each asking for a line built from a different random word, and will invoke two of them in one prompt with a random number as the shared argument:

```bash
$ ./your_program.sh -p "/apple /grape 4127"
blueberry-4127
cherry-4127
```

The third skill is seeded but never invoked.

The tester will verify that:

- Both invoked skills' lines appear in the output, each carrying the shared argument
- The word belonging to the skill that wasn't invoked is absent



### Notes

- Claude Code expands the first skill plus up to five more. You don't need to enforce that limit.
- Placeholder substitution works exactly as it did for a single skill. Each expanded body gets the same argument text.

