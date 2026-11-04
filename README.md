# build-your-own-claude-code

Course content for the ["Build your own Claude Code" challenge](https://codecrafters.io/challenges/claude-code).

Build a terminal-based AI coding assistant that calls an LLM, reads files,
edits code, and runs shell commands. This repository contains the course
definition, stage instructions, starter code, and example solutions.

## Course overview

The six base stages build the core agent:

1. Communicate with the LLM.
2. Advertise the Read tool.
3. Execute the Read tool.
4. Implement the agent loop.
5. Implement the Write tool.
6. Implement the Bash tool.

Two extensions build on that agent:

- **[Skills](extension_designs/skills.md)** (seven stages): discover and load
  reusable task instructions, pass arguments, combine skills, run bundled scripts,
  let the model choose a skill, and run a skill in a subagent.
- **[Language Server Protocol (LSP)](extension_designs/lsp.md)** (six stages):
  connect the supplied client, advertise the tool, find definitions and callers,
  synchronize edits, and use diagnostics to repair an API migration across files.
  The supplied helper handles server startup and transport. Skills is not a
  prerequisite for LSP.

Supported languages: C, C++, C#, Go, Java, JavaScript, Python, Rust, TypeScript,
and Zig.

## Repository guide

| Path | Contents |
| --- | --- |
| [course-definition.yml](course-definition.yml) | Course metadata, supported languages, extensions, and stage order |
| [stage_descriptions/](stage_descriptions/) | Learner-facing instructions for each stage |
| [starter_templates/](starter_templates/) | Shared and language-specific starter templates |
| [compiled_starters/](compiled_starters/) | Generated starter projects for each language |
| [solutions/](solutions/) | Example solutions organized by language and stage |
| [dockerfiles/](dockerfiles/) | Language runtime container definitions |
| [extension_designs/](extension_designs/) | Extension designs and the sample LSP invoice project |
| [extension_helpers/](extension_helpers/README.md) | Supplied LSP helper, language clients, and usage guides |

## Development

This challenge is developed using the [CodeCrafters course SDK](https://github.com/codecrafters-io/course-sdk).
Read its README for language support and submission workflows.

LSP-specific setup and validation are documented in the
[extension design](extension_designs/lsp.md#run-the-lsp-checks-locally).
See the [invoice exercise](extension_designs/lsp_exercise/README.md) for the
sample API migration and the [helper guide](extension_helpers/README.md) for
the supplied clients.
