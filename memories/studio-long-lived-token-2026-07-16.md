---
name: studio-long-lived-token
description: Studio authenticates claude-p with a machine-local 1-year token (shared with the VPS), off the fragile synced-credential chain; renew by July 13, 2027
metadata:
  type: project
---

# Studio long-lived Claude token (2026-07-16)

The Studio is now off the shared `.credentials.json` → Parameter Store sync chain for
headless `claude -p`. It reads a machine-local long-lived token at
`~/.claude/oauth-token` (0600, raw token, no JSON), same mechanism as the VPS.
See [[vps-long-lived-token]].

## What broke (2026-07-16)

At ~6:00 AM the Studio's Keychain item `Claude Code-credentials` was wiped — accessToken,
refreshToken, and expiresAt all zeroed (metadata retained). The synced `.credentials.json`
had expired at 5:47 AM and its refresh returned HTTP 400 "Invalid request format" (empty
refresh token). Every headless `claude -p` call failed from 6 AM on. meal-tracker's
`scan.py` retried each unclassified photo every cron cycle → ~100 failed calls/hour →
tripped the "100 calls this hour" alert. The interactive VS Code session kept working
because it coasts on an in-memory access token obtained before 6 AM.

## The trap that cost time

A **fresh** `claude setup-token` grant on the Studio was *also* rejected: HTTP 401
"OAuth access token is invalid." That looked like an account-level lockout — but it was
not. The decisive test: **the VPS's own long-lived token still worked on the same
account.** So the account was fine; the Studio's grant was bad because it was authorized
through the **Studio's Chrome claude.ai session, which is stale/wrong**. (The VPS token
was authorized via the MBP's Chrome, the correct account.)

**Lesson:** before concluding "account is locked," test another machine's token on the
same account (VPS). If it works, the failure is machine-local, and a Studio-side
`setup-token` will keep minting invalid tokens until its Chrome claude.ai login is fixed.

## The fix

Copied the VPS's already-valid token to the Studio — it is an account bearer token, not
machine-bound:

```
scp -q vps:/root/.claude/oauth-token ~/.claude/oauth-token && chmod 600 ~/.claude/oauth-token
```

Verified: `claude-p` returned exit 0; meal-tracker `scan.py` has logged clean (all `ok`)
every hour since 14:23. Wrapper Build 20+ prefers `~/.claude/oauth-token` over
`.credentials.json` and exports `CLAUDE_CODE_OAUTH_TOKEN` to the CLI subprocess.

**⚠️ RENEW BY July 13, 2027** — same token as the VPS. To give the Studio its OWN token
instead: first fix Chrome's claude.ai login on the Studio, then run the recipe
`~/apps/computer-use-local/recipes/claude-setup-token-pexpect.py`.

## Follow-ups noted

- A hook is prepending the session announcement ("You are on the MacStudio, voice on.")
  to headless `claude-p` stdout despite `CLAUDE_P_AUTOMATION=1`. meal-tracker tolerates it
  (substring match on FOOD_YES/FOOD_NO) but strict parsers (session namer) may not.
- The wrapper's auto-recovery pulls the stale Parameter Store creds over a fresh local
  token on any failure — counterproductive once a machine is on a local long-lived token.

Related: [[vps-long-lived-token]], [[reference-claude-p-keychain-harvest]],
[[reference-claude-p-auth-keychain]].
