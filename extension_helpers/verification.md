# LSP revision verification

Checked locally on 2 November 2026. The companion tester contains the matching
four-stage registration, reference agent, fixtures, transport and regressions.

## Passed

- Complete offline tester suite from the updated companion checkout:
  `go test -count=1 -skip '^TestStages$' ./...` with TESTER_DIR set to that checkout.
  This includes 16 graded cases, recorded-output comparisons, seven broken-agent
  regressions and course/tester stage registration checks.
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
- Four stage descriptions contain 336, 249, 280 and 295 prose words respectively,
  excluding code blocks. Markdown formatting, JSON/YAML parsing, exact course/
  tester YAML equality, starter/template parity, shared transport source parity
  and diff whitespace checks passed.

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
- Official stage-ID allocation and deployment. Existing IDs were retained;
  ls1, ir2 and hv2 were retired. No publication was performed.

Scripted integration runs prove the wiring and causal feedback gate. They do not
prove that a live model will make the same initial mistake or repair it reliably.
