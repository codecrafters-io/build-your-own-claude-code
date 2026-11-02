# LSP revision verification

Checked locally on 2 November 2026. The companion tester contains the matching
five-stage registration, reference agent, fixtures, transport and regressions.

## Passed

- Complete offline tester suite from the updated companion checkout:
  `go test -count=1 -skip '^TestStages$' ./...` with TESTER_DIR set to that checkout.
  This includes 16 graded cases, recorded-output comparisons, ten broken-agent
  regressions and course/tester stage registration checks.
- Setup passes with an agent whose navigation handler is unimplemented. Setup
  regressions reject a missing configuration call, a missing LSP tool, and an
  incomplete required schema. Every LSP case supplies a connection; the reference
  agent constructs its client and advertises LSP without an environment check.
- `go test -count=1 -race ./internal/lsp_transport ./internal/lsp_manager`,
  including fragmented initialization, queued notifications, startup failure,
  cleanup and a configuration accessed through a project symlink.
- Configured-language regressions: the helper exposes a TypeScript extension
  map, rejects missing mappings, and the reference agent opens documents using
  the configured language ID while rejecting unmapped extensions. The offline
  suite and real Pyright migration also pass with configuration-based selection.
- `go vet ./...` in the tester and standalone transport build.
- Reference integration against Pyright 1.1.414: definition, cross-file
  references, definition after an edited import, the Price API migration,
  actual return-type diagnostics, repair and clearing. Repeated three times
  after fixing project-path canonicalization.
- Native Claude Code 2.1.266 with Pyright and a local scripted model: navigation,
  the API migration, diagnostic delivery before repair, synchronization and
  clearing. This uses the product's diagnostic attachment channel.
- Python, JavaScript, TypeScript, Go, C and Java starter clients round-tripped
  JSON through a local endpoint, including an 8 KiB response. Run
  `python3 extension_helpers/verify_clients.py` to repeat these checks. The
  LSP helpers workflow runs them in CI.
- All three invoice behavior tests passed initially and after the complete API
  migration. The partial migration failed only checkout's behavior test;
  reporting and unrelated preview behavior remained correct.
- All five stage descriptions stay under 350 prose words, excluding code blocks.
  Markdown formatting, JSON/YAML parsing, exact course/
  tester YAML equality, starter/template parity, shared transport source parity
  and diff whitespace checks passed.
- Setup and definition lookup render separately in the local course editor.
  Both the extension introduction and setup define a language server and LSP
  and show the request/result route, so the context is visible while taking
  the course. Setup identifies the supplied server/helper/client and lists
  file setup, configuration retrieval, and tool registration steps.
  The revised setup shows the JSON schema to add directly to the existing tool
  list and links to a guide for all ten clients. It explains the tester-provided
  connection and the empty
  configuration request body, and covers existing checkouts missing these files.
  Its Python example was exercised with the supplied client against a temporary
  local endpoint without a learner-side environment check. The inline tool
  schema matches the starter schema; registration no longer requires loading a
  schema file. Linked client files exist and match generated starters.
  Definition lookup reuses setup's connection without repeating
  configuration or tool registration.
- Stages two through five use complete helper request/notification envelopes.
  The definition response and matching model tool message, references request,
  changed-import synchronization, and diagnostic error/clearing examples were
  exercised through the supplied transport and controlled stdio fixture. All
  JSON examples parse; the diagnostic ranges and Write result examples match
  the fixture's actual publications. Diagnostics now has a numbered sequence
  covering draining, saving/synchronization, waiting, selection, and tool results.

The path fix matters: a helper initialized through a symlink must identify the
same physical project as the agent's document URIs. Otherwise real-server
reference results can omit callers even while the controlled fixture passes.

## Remaining release checks

- Compile and exercise C++, C#, Rust and Zig starter clients in their supported
  build environments. Their toolchains/dependencies were unavailable locally;
  inclusion and generated-starter parity do not establish runtime correctness.
- Live-model reliability and the existing 100-run live flakiness check with a
  valid CODECRAFTERS_SECRET_OPENROUTER_API_KEY.
- A learner pacing trial, especially the first navigation stage and notification
  freshness in the finale.
- Official stage-ID allocation and deployment. Setup uses provisional lc1;
  existing IDs were retained;
  ls1, ir2 and hv2 were retired. No publication was performed.

Scripted integration runs prove the wiring and causal feedback gate. They do not
prove that a live model will make the same initial mistake or repair it reliably.
