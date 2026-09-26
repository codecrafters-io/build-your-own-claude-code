In this stage, you'll add support for finding skills on disk and advertising them to the LLM.

### Skills

A [skill](https://code.claude.com/docs/en/skills) is a folder of instructions that you can load into the model's context on demand. Claude Code ships skills for things like reviewing pull requests or writing commit messages, and lets you add your own.

Skills live under `.claude/skills/` in the project directory. Each skill is a folder containing a `SKILL.md` file:

```
.claude/
└── skills/
    ├── apple/
    │   └── SKILL.md
    └── grape/
        └── SKILL.md
```

A `SKILL.md` file has two parts: **frontmatter** (metadata between `---` markers) and a **body** (everything after it):

```markdown
---
name: apple
description: Deploys the apple service to production.
---

Run the deploy script and report the version that was deployed.
```

The frontmatter tells your program what a skill is for. 

### Progressive disclosure

The obvious way to tell the model about a skill is to paste its whole `SKILL.md` into the prompt. That doesn't scale: ten skills of two hundred lines each would fill the context window before the user has asked anything.

Skills solve this with **progressive disclosure**. Claude loads only the front matter first, and loads the body and other dependencies when the skill is invoked. There are three levels (as given in the  [Agent Skills standard](https://agentskills.io/specification#progressive-disclosure)):


| Level | What gets loaded                    | Rough size            | When                         |
| ----- | ----------------------------------- | --------------------- | ---------------------------- |
| 1     | Name, description & other fields    | ~100 tokens per skill | Always                       |
| 2     | The `SKILL.md` body                 | Under 5,000 tokens    | When the skill is used       |
| 3     | Bundled scripts and reference files | Unbounded             | When the body points at them |


For this stage, you'll implement level 1 only.

### Advertising skills

Lets walk through how a skill is advertised: 

1. Scan `.claude/skills/`, run through the skill folders and parse the frontmatter to read the `name` and `description` out of each `SKILL.md`, and add them to your system prompt. Do **not** include the bodies.

For example, if there are two skills: `apple` and `grape`, your system prompt will look like this. 

```
You have access to the following skills:

- apple: Deploys the apple service to production.
- grape: Runs the grape test suite and reports failures.
```

1. You already have an initial conversation history: the `messages` array with the user's prompt. Add the  `system` prompt at the front of the `messages` array.

```diff
 messages = [
+  { "role": "system", "content": "You have access to the following skills:\n\n- apple: ..." },
   { "role": "user", "content": prompt }
 ]
```



### Tests

The tester will create a random number of skill folders, then describe a task taken from one skill's description and ask which skill fits:

```bash
$ ./your_program.sh -p "Which skill would help me deploy the apple service? Respond with only the skill name."
apple
```

### Notes

- We recommend you implement a proper YAML parser at this stage. It'll come in handy in later stages.
- The [Agent Skills standard](https://agentskills.io/specification) requires the frontmatter `name` to match the folder name, so you can read either one, and later stages invoke skills by folder name.

