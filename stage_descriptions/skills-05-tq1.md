In this stage, you'll add support for skills that bundle an executable script.

### Disclosure level 3

A skill folder can hold more than `SKILL.md`. The [Agent Skills standard](https://agentskills.io/specification#optional-directories) names three conventional subfolders: 

- `scripts/` for executable code
- `references/` for documentation the model reads on demand
- `assets/` for templates and data.

All three are disclosure level 3: the model loads them only if the body tells it to. This stage covers `scripts/`.

This is what makes skills more than stored prompts. A body of two lines can point at a script of two hundred, and neither the script nor its output costs any context until it runs.

A skill with a bundled script looks like this:

```
.claude/
└── skills/
    └── apple/
        ├── SKILL.md
        └── scripts/
            └── checksum.sh
```



### Referencing a script

A skill shouldn't have to hardcode its own location. It might be installed under the project, under the user's home directory, or somewhere else entirely. So a body names its bundled files with [paths relative to the skill's own folder](https://agentskills.io/specification#file-references):

```markdown
---
name: apple
description: Reports the checksum of the project data file.
---

Run `scripts/checksum.sh` using the Bash tool.

Respond with only the value it prints, and nothing else.
```

On its own that path leads nowhere: your program runs in the project root, and the script is at `.claude/skills/apple/scripts/checksum.sh`.

Your program already loads a skill's body into `messages` when the user invokes it. The new work here is telling the model to read the path as relative to the skill's folder. Naming that folder alongside the instructions is one way:

```
Skill: apple (located at .claude/skills/apple)
Paths in the instructions below are relative to that folder.

Run `scripts/checksum.sh` using the Bash tool.

Respond with only the value it prints, and nothing else.
```

So your `messages` array for `/apple` becomes:

```js
[
  { "role": "system", "content": "You have access to the following skills:\n\n- apple: ..." },
  { "role": "user", "content": "Skill: apple (located at .claude/skills/apple)\nPaths in the instructions below are relative to that folder.\n\nRun `scripts/checksum.sh` using the Bash tool.\n\nRespond with only the value it prints, and nothing else." }
]
```

The model now has both halves: the folder from your message, and the relative path from the body. It joins them, calls the `Bash` tool you built in the base stages with `.claude/skills/apple/scripts/checksum.sh`, and your agent loop feeds the output back so it can report the value.

### Tests

The tester will create a data file with random contents. It will also create a skill that references a script to get the hash of the random contents. 

```bash
$ cat .claude/skills/apple/scripts/checksum.sh
#!/usr/bin/env bash
sha256sum data.txt | cut -c1-8
```

It will then invoke the skill:

```bash
$ ./your_program.sh -p "/apple"
9f2b4c1a
```

The tester will verify that:

- Your program outputs the eight-character checksum of the file the tester created



### Notes

- A project-relative folder like `.claude/skills/apple` is enough here, since the `Bash` tool runs from the project root.
- Skills can also [bundle](https://agentskills.io/specification#optional-directories) `references/` and `assets/` next to `scripts/`, and a body names those the same way. We won't deal with them in this extension.

