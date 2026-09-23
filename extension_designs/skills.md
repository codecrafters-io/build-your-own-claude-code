# Skills — extension design

Design record produced at phase 1 of the **Author a Course Extension** procedure, before any file was written. Kept so the shape of the extension can be reviewed and argued with independently of the stage descriptions that implement it.

**Extension:** `skills` — Skills

**Description:** In this challenge extension, you'll add support for Skills in your Claude Code implementation. A skill is a folder of instructions for one specific task; your agent finds skills on disk and loads one only when it's needed. Along the way you'll learn about progressive disclosure, frontmatter parsing, argument substitution, and letting the model choose a skill on its own.

The "learn about" list covers all six shipped stages. Stacking is left implicit under argument substitution rather than named, since the list is already at three items and the house shape keeps it short.

Three sentences rather than the house two, because "Skills" is a term coined in 2025 — unlike Bitmaps or Sorted Sets, a reader can't infer it and has nothing to look it up against. The gloss is deliberately one plain sentence plus one on the loading behaviour; an earlier draft packed both into the opening sentence and made it 29 words, which is what prompted the rewrite.

**Axis:** who triggers a skill, and how much context it costs

**Sources:** [Claude Code — Extend Claude with skills](https://code.claude.com/docs/en/skills) (the implementation this course reproduces) · [Agent Skills](https://agentskills.io/home) and its [specification](https://agentskills.io/specification) (the open standard, published December 2025) · **[How to add skills support to your agent](https://agentskills.io/client-implementation/adding-skills-support)** (the implementer's guide — the closest thing to a reference solution for this extension) · [Using scripts in skills](https://agentskills.io/skill-creation/using-scripts) · [Optimizing skill descriptions](https://agentskills.io/skill-creation/optimizing-descriptions) · [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) (design rationale)

The implementer's guide is the one to read first on any future revision. It decomposes the task into discover → parse → disclose → activate → manage, which is the same spine this extension arrived at independently, and it documents the edge cases at each step.

Where the two specs disagree, the course follows Claude Code, because that's the program the learner is rebuilding. One case matters: the standard **requires** frontmatter `name` to match the parent directory name, while Claude Code tolerates a mismatch and resolves the command from the directory. Stage 1 teaches the standard's rule, since a skill that violates it is invalid everywhere else.

**Stages:** 6 — all built

## Stages

| # | Slug | Stage name | Difficulty | Objective | Tester assertions | New harness | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `vh1` | Advertise skills to the LLM | `easy` | Read `.claude/skills/*/SKILL.md` and inject names and descriptions into the system prompt | Model reports the correct count; model names the skill matching a described task | — | built |
| 2 | `jd8` | Invoke a skill by name | `easy` | Resolve `/name` to a folder and load only that body | Output is the token hidden in the invoked skill's body, with a decoy seeded alongside | — | built |
| 3 | `wd2` | Pass arguments to a skill | `easy` | Substitute `$ARGUMENTS` and `$0`/`$1` into the body | `$ARGUMENTS` reproduces the full string; `$1 $0` resolves reversed | — | built |
| 4 | `sk5` | Stack multiple skills | `medium` | Expand the run of `/name` tokens at the start of a message, passing the trailing text to each | Both invoked skills' `<token>-<argument>` lines appear; the uninvoked skill's token does not | `ContainsAllAssertion`, `AllOfAssertion` | built |
| 5 | `tq1` | Run a script bundled with a skill | `medium` | Body names `scripts/<file>` relative to the skill folder; the program tells the model where that folder is | Output is the 8-character checksum of a randomly seeded data file | `ChecksumOf` plus script seeding | built |
| 6 | `gq2` | Let the model choose a skill | `medium` | Model matches a request against descriptions and loads a body itself | Output is the matching skill's token, with a decoy description seeded | — | built |

**Placement.** Stacking sits at 4 because it depends on name resolution (2) and arguments (3) and on nothing later. The two stages that hand work to the model close the extension: the script stage, where the model executes something the skill shipped, then model-invocation, where the model picks the skill in the first place.

**Shape after the cuts.** Three stages designed on paper were dropped or deferred rather than built; see the deviations section for each. What remains is three `easy` openers and three `medium`, with no `hard`. The ramp is legal — stage 1 is `easy`, no jump exceeds one tier, and "at most one `hard`" is satisfied vacuously — but the extension now ends on the same tier it reaches at stage 4, and `tu9` is the stage that would restore a peak if it's ever built.

## Candidates surfaced late, from the implementer's guide

These came out of `adding-skills-support.md`, read after the stage shape was settled. Recorded rather than adopted. Both are stronger than they look: deterministic and requiring no LLM call — though with `--list-skills` now gone (see the deviations below), either would have to assert through the model or reintroduce a non-model surface of its own.

**Lenient parsing of malformed frontmatter.** The guide devotes a section to it, because skills authored for one client routinely break another's YAML parser. The canonical trap is an unquoted colon: `description: Use this skill when: the user asks about PDFs` is invalid YAML that most parsers reject and clients are expected to recover from. The prescribed behaviour is graded — warn and load on a `name`/directory mismatch or an over-long name; *skip* the skill on a missing description or unparseable YAML. A stage seeding one valid skill, one colon-in-description skill, one with no description, and one with broken YAML, then exact-matching the listing, tests all four paths at once with no model involved.

This conflicts with a note currently in stage 1: *"You don't need a real YAML parser. In every test, the frontmatter is exactly the two lines `name:` and `description:`."* That's a legitimate scope fence for stage 1, but it should read "not yet" rather than "not ever" if this stage is adopted.

A skipped-skill assertion also gets harder without a listing surface: proving a malformed skill was *skipped* means proving its name never reached the prompt, which is `DoesNotContainAssertion` against a model rather than an exact stdout diff.

**`.agents/skills/` and lookup precedence.** The guide recommends scanning both the client's native directory and `.agents/skills/`, at both project and user scope, so that skills installed by any compliant client are visible — this is the entire interoperability story of the open standard, and the extension currently ignores it. It pairs naturally with the collision rule the guide names as universal: **project-level skills override user-level skills**, with a warning logged when one shadows another. This subsumes the "personal skills under `~/.claude/skills/`" candidate rejected earlier, and is a better stage than that one was, because the precedence rule gives it a sharp assertion.

**One smaller correction, not a stage.** The guide recommends including each skill's `location` (the absolute path to its `SKILL.md`) in the catalog alongside name and description, so the model can resolve the skill's relative paths; stage 1 omits it, and stage 5 supplies it per-invocation instead.

The second item here used to be a claimed divergence between the standard's relative paths and Claude Code's `${CLAUDE_SKILL_DIR}`. It was tested and turned out not to exist — see the deviations below.

## Out of scope

Features in the specification that this extension deliberately doesn't teach:

- **`allowed-tools` and `disallowed-tools`** — the meatiest remaining feature, but it pre-approves or withholds tools through a permission system the base course never builds. The tester runs everything under `bypassPermissions`, so there's nothing for a grant to be visible against.
- **`context: fork` and `agent`** — running a skill in a forked subagent needs subagent infrastructure the course doesn't have.
- **Named arguments** (`arguments: [issue, branch]` giving `$issue`) — real, but it's the same substitution stage 3 already teaches. A note on stage 3, not a stage.
- **`references/` and `assets/`** — the other two conventional subfolders, for documentation and for templates and data. Both are mechanically identical to `scripts/` from the program's point of view: the body names a relative path and the program tells the model where the folder is. The stage that taught `references/` was cut for exactly this reason; see the deviations below.
- **`disable-model-invocation` and `user-invocable: false`** — withholding a skill from the model, or from the user. Both were designed as stages and `disable-model-invocation` was built before being cut; see the deviations below.
- **Frontmatter validation** — the standard constrains `name` to 1–64 lowercase alphanumeric characters and hyphens, with no leading, trailing, or consecutive hyphens. Real, checkable, and dull; it teaches regex rather than anything about agents.
- **`paths:` glob activation** — auto-loading a skill only when matching files are in play. Testable in principle, but the trigger is a model judgement, which makes it the flakiest thing in the spec.
- **Personal skills under `~/.claude/skills/`, and name collisions with project skills** — superseded by the `.agents/skills/` candidate above, which covers the same ground with the standard's interop story attached.
- **Protecting skill content from context compaction, and deduplicating repeat activations** — both in the implementer's guide's "manage skill context over time" step. Both presuppose a compaction system the base course doesn't build.
- **Trust-gating project-level skills** — the guide notes that a freshly cloned repository can inject instructions into the agent's context, and suggests gating project skills on a trust check. Real and security-relevant, but it needs a trust model the course has no other use for.
- **`.claude/commands/` compatibility** — custom commands have been merged into skills, so `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` both produce `/deploy`. Historical baggage, not a concept worth a stage.

## Review notes

**The extension has no CI coverage yet.** Phase 6 of the authoring procedure is incomplete: there is a reference implementation under `internal/test_helpers/scenarios/skills_stages/users_code_pass_all/`, and the `skills_manager` unit tests pass, but no fixtures have been recorded and `make test_flakiness` has never run. Both need a live model via `CODECRAFTERS_SECRET_OPENROUTER_API_KEY`. Until that happens the stage tests have never executed end to end, and "the unit tests pass" should not be read as more than it says.

**Harness work clusters in the middle.** Stages 4 and 5 need new tester code; stages 1, 2, 3, and 6 need none. That's the argument for building the harness as one upfront change rather than drip-feeding it per stage.

**Stage 1's "don't include the bodies" rule is stated but not tested.** Every skill there is seeded with the same inert body, so a learner who pastes whole `SKILL.md` files into the system prompt still counts correctly and still matches a description to a name. Stage 2's decoy is the first thing that punishes it, though only probabilistically — a program that loads both bodies gives the model two contradictory instructions and picks the right one about half the time. Stage 4 closes it deterministically: its uninvoked skill's token can only appear if an uninvoked body was loaded. Accepted deliberately at stage 1, whose notes tell the learner plainly that the rule bites later rather than there.

**Stage 5 can't distinguish "ran the bundled script" from "ran an equivalent command".** The randomised data file means something must execute, but an end-to-end tester can't see which. Accepted and documented in the stage's notes rather than designed around.

**Stage 1's exact-count assertion is the flakiness risk**, more so than stage 6. The base course already retreated from an exact count to `MinimumValueAssertion` in `aq1` on a near-identical question. It is the learner's first contact with the extension, so a flaky failure here reads as "the extension is broken" rather than "this one check is fussy". If it proves flaky, the count is the weaker of stage 1's two assertions; the description-matching one carries the stage on its own.

**Stage 4's negative assertion is the one to watch in `make test_flakiness`.** It asserts that the uninvoked skill's token never appears. That should be robust — a model cannot emit a random fruit word it was never shown — but the model does hold the `Read` tool and could in principle go looking through `.claude/skills/` unprompted. Verify before shipping.

## Deviations from the original proposal

**Three of the nine designed stages were cut, taking the extension from nine to six.** Each for a different reason, and only one of them was a design error.

**`xa9` (Restrict model invocation) was built, then removed as too easy.** Honouring `disable-model-invocation: true` is a one-line filter on the list the program already assembles in stage 1. The stage had two sound assertions and a decisive negative test, so nothing was wrong with it as a *test* — it just didn't ask the learner to do anything. Removing it deleted `stage_test_skills_restrict.go`, the `DisableModelInvocation` field on `Skill`, and the frontmatter branch that emitted it. `DoesNotContainAssertion` survived the cut because stage 4 picked it up.

**`qc3` (Load a reference file on demand) was dropped without being built — a design error caught late.** The case for it, recorded here at the time, was that the engineering post's central worked example is the PDF skill reading `forms.md` only when filling a form, making selective document loading the canonical illustration of progressive disclosure, and that it was the cheapest stage in the extension to test.

Both arguments are true and neither is the right test. The question that decides whether something is a stage is *what does the learner implement that they didn't implement last stage?* — and the answer here is nothing. Whichever of `qc3` and `tq1` came first would teach the program to tell the model where the skill folder lives; the second would then pass on the code written for the first. The only thing distinguishing `qc3` was its assertion that the irrelevant file's token stayed absent, and that is a property of the model's judgement, not of the submission: no code the learner writes causes selectivity. The version that would test the submission asserts on the outbound request, proving the program didn't preload the reference files — which needs the `tu9` recorder.

Worth keeping as a warning: this stage was rejected in the first pass for being too close to the script stage, then promoted on a pedagogy argument, then dropped again on the original grounds. The first instinct was right, and two rounds of documented reasoning talked past it.

**`tu9` (Inject dynamic context) is deferred, not rejected.** It is the only stage here that does work *before* the model is called rather than shaping what the model sees, and it was the extension's only `hard`. Building it means building a proxy request recorder, because asserting on the model's *output* would be the wrong test: the model has Bash, so it could produce the value by running the command itself and pass without implementing injection at all. The assertion has to be on the outbound request.

The proxy can almost do this today. `proxy_server/validator.go` defines `ValidationFunc` as a per-endpoint `func(*http.Request) (bool, string)` hook, and `modelValidator` already reads the full body, restores it with `io.NopCloser(bytes.NewBuffer(...))`, and unmarshals it to inspect a field. What's missing is only plumbing: `StartProxyServer` takes no extra hooks and `newProxyServer` hardcodes `{modelValidator}`. Add a **recorder** rather than reusing the validator hook — a failing validator returns HTTP 400 to the learner's program, which surfaces as a confusing upstream error instead of a test failure, whereas a recorder captures request bodies and lets the stage assert afterwards with a normal "Expected X, got Y" message, per rule G.

**Stacking's argument rule came from the docs, not from the design.** The design table described stage 4 as "expand several `/name` invocations at the start of one message, passing the trailing text to each", which leaves open where the trailing text begins. Claude Code's documented rule is sharper: expansion runs from the start of the prompt, the first token that isn't an inline user-invocable skill ends the run, and that token and everything after it become the argument text for every expanded skill. So `/apple 4127 /grape` expands only `apple` and passes it `4127 /grape`. The stage description teaches the documented rule and the reference implementation follows it. Claude Code also caps expansion at the first skill plus five more; the course states the cap but doesn't ask the learner to enforce it.

**Positional arguments are zero-based**, as the first draft specified. They were briefly changed to one-based on the incorrect assumption that Claude Code has no `$0`; the [official spec](https://code.claude.com/docs/en/skills) defines `$N` as shorthand for `$ARGUMENTS[N]`, so `$0` is the first argument. Reverted.

**Listing and advertising were merged into one stage, and `--list-skills` was dropped.** The original stage 1 printed `<name>: <description>` to stdout behind a `--list-skills` flag; the original stage 2 put the same two fields into the system prompt. The filesystem scan and frontmatter parse were shared, leaving roughly ten lines of genuinely new code in the second stage, and the flag appeared in exactly one stage and does not exist in Claude Code — so the learner built a surface, used it once, and discarded it.

What the split bought was a deterministic, LLM-free opener: a parsing bug produced a clean stdout diff instead of a wrong model answer. That was worth naming before giving up. Merging trades it away, and the cost lands on debuggability rather than on coverage, since both of the old stage 2's assertions survive intact. Stage 1's notes now tell the learner to print the assembled system prompt to stderr while developing, which recovers most of the lost visibility — the tester reads only stdout.

The merge also retires the sort-order question the original design flagged as an open problem: with no listing output, there is no ordering for an exact-match assertion to be unfair about. `ListSkillsTestCase`, `ExpectedListing`, and `ListingLine` are deleted; `zp8` returns to the unallocated slug pool.

**The script stage uses relative paths, not `${CLAUDE_SKILL_DIR}` — settled by experiment, not by reading.** Two drafts argued this from documentation and both were wrong: first that relative paths cannot work for an executed command because the Bash tool's working directory moves, then that the two specs genuinely diverge and the course should follow Claude Code.

Running it against Claude Code 2.1.266 settled it. Two skills identical but for the script reference, with the script itself using an absolute path to its data file so the only variable was the reference:

| Body says | Command Claude Code ran | Result |
| --- | --- | --- |
| `${CLAUDE_SKILL_DIR}/scripts/checksum.sh` | `/private/tmp/skilltest/.claude/skills/atlas/scripts/checksum.sh` | correct checksum |
| `scripts/checksum.sh` | `/private/tmp/skilltest/.claude/skills/nimbus/scripts/checksum.sh` | correct checksum |

Both resolved to an absolute path on the first tool call, with no failed attempt and no self-correction, so this is Claude Code resolving the reference rather than the model recovering from a broken one. The standard's form and the placeholder behave identically in the real product, which means there was never a divergence to take sides on. The course teaches the standard's relative paths.

What the learner implements is consequently more honest than a string replace: the program has to tell the model where the skill lives, which is the implementer's guide's `location` recommendation arriving by a different route.

**Stage 1 teaches the standard's `name` rule, not Claude Code's.** An intermediate draft said the frontmatter `name` is "only a display label", which is true of Claude Code's resolution behaviour and false as a general rule — the Agent Skills standard requires `name` to match the parent directory. A skill relying on the mismatch is invalid outside Claude Code, so the stage teaches the constraint and the tester always satisfies it.
