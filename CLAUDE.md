# claude-p-wrapper

> Inherits from the global CLAUDE.md (`~/.claude/CLAUDE.md`). This file covers repo-specific conventions only.

## What This Is

A drop-in wrapper for the non-interactive Claude Code CLI that logs every call, fires hourly Gmail alerts, and suppresses calls past a hard cap to protect the Max plan allowance.

## Tech Stack

Single-file Python 3 script. No dependencies beyond the stdlib. Runs on macOS and Linux.

## Layout

- `claude-p` — the wrapper executable
- `claude-p-report` — companion script that summarizes the JSONL log by caller, model, and hour
- `~/apps/cc/bin/claude-p` and `~/apps/cc/bin/claude-p-report` are symlinks into this repo so existing call sites keep working unchanged
- The log lives outside this repo at `~/apps/cc/logs/claude-p-usage.log` so the daily reflection and other readers can find it where they always have

## Rate Limits

- 100 calls per hour: warning email, call still proceeds
- 400 calls per hour: critical email, call is suppressed (returns exit 0, empty stdout)
- One email per tier per hour to avoid flooding
- The `EXEMPT_CALLERS` allowlist in `claude-p` bypasses the hard cap for event-driven callers (one user action equals one call). Timer-driven callers must never be exempted.

## Wrapper Version

`WRAPPER_VERSION` at the top of `claude-p` tags every log line. Bump it whenever the log schema changes so older lines stay parseable. Adding a field is additive and does not require a bump; renaming or removing one does.

## Build Number

- Stored in `build.txt` (plain integer, root of repo)
- Bump on every commit: `echo $(($(cat build.txt) + 1)) > build.txt`
- Commit message format: `Build X: short summary`
- Always announce after bumping: "Build X of `claude-p-wrapper`: short summary" — spoken and written

## Deploy

- Push to GitHub, then `git pull` on every machine that has `~/apps/claude-p-wrapper`
- After every `git push`, run `bash ~/apps/cc/post-push-sync.sh` (or use `gpush`) to sync other machines
- The symlinks in `cc/bin/` are tracked by the `cc` repo, not this one — they only need to land once per machine
