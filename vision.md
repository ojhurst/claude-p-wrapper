# Vision

## The Problem

`claude -p` is the primary way my automation talks to Claude. The Max plan makes that free in dollars, but the plan has a per-hour usage limit and I have somewhere between thirty and fifty scripts that can hit it. When the plan limit trips, the whole stack degrades silently and I find out later, usually after Kelly-Sloan-Beck-level incidents where a real customer reply did not go out.

Until now every script rolled its own `subprocess.run(["claude", "-p", ...])` with its own ad hoc error handling and its own log file, or no log at all. There was no way to answer the obvious audit questions — which process is calling Claude most often, which model, how long are the calls taking, and when are we about to hit the limit.

## What This Is

A single wrapper executable — `claude-p` — that every automation script calls instead of `claude -p` directly. It:

1. Forwards every invocation to the real Claude CLI unchanged, so it is a true drop-in.
2. Logs structured JSON lines to `~/apps/claude-p-wrapper/logs/claude-p-usage.log` with enough detail to audit any call after the fact.
3. Tracks calls per hour and fires Gmail alerts at a warning tier (100/hr) and a critical tier (400/hr), suppressing further calls beyond the critical tier.
4. Ships with a companion `claude-p-report` that summarizes usage by model, by caller, by hour, and by purpose.

## What This Is NOT

- Not a quota manager. It does not smooth calls across the hour, retry on limit, or queue. It logs, alerts, and refuses at the hard cap. Rate-smoothing is a job for the callers.
- Not a response cache. It does not dedupe by prompt hash even when the exact same prompt fires twice. The log can flag dedupe candidates but the wrapper stays out of the way.
- Not a model router. Callers still pass `--model` themselves. The wrapper records which model was used but does not pick one.
- Not a secret keeper. It forwards everything the caller passed and keeps nothing sensitive out of the log beyond a prompt preview.

## Phases

**Phase 1 — ship the audit fields (now).** model, ancestry, cwd, caller_path, purpose env tag, machine, call_id, wrapper_version, prompt_sha256, stderr_tail, error_category, sid fallback. Enough to answer every audit question I asked for today.

**Phase 2 — adoption.** Migrate the ~30 existing call sites off bare `claude -p` to the wrapper. Starting list in the call-site inventory we already have from the handoff session.

**Phase 3 — outcome tagging.** Callers supply `CLAUDE_P_PURPOSE` so the report can group by feature ("gkp.lead_reply", "screenshot_rename") instead of just by script name.

**Phase 4 — optional.** Stdout preview via tee (currently skipped because it would change stdout proxying), claude-cli-version caching, per-day rollups, dashboard on the command center.

## Non-Negotiables

- The wrapper never drops a call silently except at the hard cap, and the hard-cap suppression is logged.
- The log is append-only JSONL. Old lines keep their schema; new fields are additive. `wrapper_version` on every line makes schema changes safe.
- The wrapper lives in its own repo so its build number, logs, and commit history tell a clean story.
- No paid API fallback. If `claude -p` is down, the wrapper logs the failure and returns a nonzero exit. Callers decide what to do.
