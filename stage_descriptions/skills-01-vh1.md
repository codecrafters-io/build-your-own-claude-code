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

The frontmatter tells your program what a skill is for. Claude Code accepts [many more frontmatter fields](https://code.claude.com/docs/en/skills#frontmatter-reference) than `name` and `description`, and you'll implement one of them in later stages.

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

Scan `.claude/skills/`, parse the frontmatter to read the `name` and `description` out of each `SKILL.md`, and add them to your system prompt. Do **not** include the bodies.

Any clear format works, since the tester checks the model's answers rather than your exact wording. For example:

```
You have access to the following skills:

- apple: Deploys the apple service to production.
- grape: Runs the grape test suite and reports failures.

To use a skill, read .claude/skills/<name>/SKILL.md.
```

Your program doesn't send a system prompt yet. Your `messages` array is initialized with the user's prompt, and the agent loop appends the model's replies and your tool results onto it. Add a `system` message at the front, where you initialize the array:

```diff
 messages = [
+  { "role": "system", "content": "You have access to the following skills:\n\n- apple: ..." },
   { "role": "user", "content": prompt }
 ]
```



### Tests

The tester will create a random number of skill folders, then run your program twice.

First, it asks for a count:

```bash
$ ./your_program.sh -p "How many skills are available to you? Respond with only a number."
2
```

Then it describes a task taken from one skill's description and asks which skill fits:

```bash
$ ./your_program.sh -p "Which skill would help me deploy the apple service? Respond with only the skill name."
apple
```



### Notes

- We highly recommend you implement a proper YAML parser at this stage. It'll come in handy in later stages.
- The [Agent Skills standard](https://agentskills.io/specification) requires the frontmatter `name` to match the folder name, so you can read either one, and later stages invoke skills by folder name.
- Both checks run through the model, so a bug in your parsing surfaces as a wrong answer rather than a clear error. While developing, print the system prompt you assembled to stderr to catch these errors.

