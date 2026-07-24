---
name: brain-fallback-and-smart-alerts
description: How claude-p behaves when OAuth is down as of Build 23 — it no longer goes dark or sends terse emails; it serves via the API-key brain and alerts via grace-gated smart receipts. Read this before diagnosing any "claude-p auth" issue.
metadata:
  type: reference
---

As of claude-p-wrapper **Build 23** (WRAPPER_VERSION 9, 2026-07-24), a `claude -p`
OAuth outage no longer means "callers go dark + James gets a terse email." The
behavior changed, so diagnose accordingly:

## What now happens on an auth failure
1. **The caller is SERVED, not failed.** `brain_serve()` answers the call via the
   `/anthropic/api-key` brain (claude-login's `brain.ask()`) — a credential that
   survives an OAuth outage. The caller gets a real answer, exit 0. It honors
   `--system-prompt`/`--append-system-prompt` and wraps `--output-format json` in a
   CLI-shaped envelope (with `brain_fallback: true`). These calls are **metered
   (paid API)**, logged with `error_category: "brain_fallback"`. Cost is the
   deliberate tradeoff for never going dark (James's call).
2. **Alerts are grace-gated + PONG-verified.** `handle_auth_failure()` does NOT
   email on the first failure. It holds until the outage is sustained ≥ `GRACE_MIN`
   (15 min, measured from the usage log's unbroken down-streak), then runs a live
   PONG re-verify; if PONG passes (self-healed), it suppresses the alert entirely.
   Only a sustained + still-failing outage escalates.
3. **Escalation = claude-login's SMART receipt**, via
   `claude_login.heal("claude-cli", allow_browser=False)` — runs the non-browser
   rungs (Parameter Store pull, CLI refresh, keychain unlock), can silently heal,
   and only emails the "what I tried, brain-sharpened" receipt if it truly can't.
   The old terse `[claude-p] API 401` email is a **backstop only** (claude-login
   import fails). The async browser-login LaunchAgent kickstart still fires (macOS).

## Diagnostic implications for future-me
- A <15-min auth blip that self-heals produces **NO email** now — that is correct,
  not a broken alerter. Don't "fix" the missing email.
- Grep the usage log for `"error_category": "brain_fallback"` to see the outage
  window and which callers were served in degraded mode.
- `CLAUDE_P_INNER=1` marks a nested claude-p spawned by the PONG re-verify or the
  heal ladder — it skips recovery/serve/escalate to avoid recursion. Set it if you
  script a claude-p call that must behave like plain `claude -p`.

## Generic cron alerts, too
Same day: `claude_login.report(tag, command, exit_code, logs)` + the
`claude-login report` CLI turn ANY failing job's raw log into a brain-triaged
receipt (real error + root cause + one fix). `~/apps/cc/run-or-alert.sh` now routes
through it instead of dumping 50 raw lines. See [[../../claude-login]] core.report.

Born from the 2026-07-24 session: James asked why the `[claude-p] API 401` email
was dumb and didn't say what it tried, and "why doesn't it just use the Anthropic
key" — the brain existed (claude-login `brain.py`) but was only wired for diagnosis,
never for serving callers. Now it serves.
