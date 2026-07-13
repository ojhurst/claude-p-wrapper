---
name: vps-long-lived-token
description: VPS authenticates claude-p with its own 1-year setup-token — no longer depends on MBP keychain harvest; renew by July 13, 2027
metadata:
  type: project
---

# VPS long-lived Claude token (2026-07-13)

The VPS no longer depends on the MBP → Parameter Store → pull credential chain for
`claude -p`. It has its own long-lived OAuth token from `claude setup-token`
(1-year lifetime, inference scope, tied to James's Max subscription).

- **Live copy:** `/root/.claude/oauth-token` on the VPS (0600, raw token, no JSON)
- **Backup:** Parameter Store `/claude/vps/CLAUDE_CODE_OAUTH_TOKEN` (SecureString)
- **Wiring:** Build 20 of `claude-p` — if `~/.claude/oauth-token` exists, the wrapper
  exports `CLAUDE_CODE_OAUTH_TOKEN` for the CLI subprocess and prefers it in
  `read_oauth_token()` (SDK path). Machines without the file (MBP, Studio) are unaffected.
- **Verified:** `claude-p` returned a live response on the VPS with
  `.credentials.json` removed entirely (2026-07-13).

**⚠️ RENEW BY July 13, 2027.** Flow: `claude setup-token` in a wide tmux pane on the VPS
(`tmux new -d -x 400 -s setup-token 'claude setup-token'`), open the printed URL in a
browser logged into claude.ai (James's MBP Chrome), click Authorize, then take the
`code` and `state` params FROM THE CALLBACK TAB URL (`platform.claude.com/oauth/code/callback`)
and paste `code#state` into the tmux prompt. The success page does NOT display the code —
the callback URL carries it. JS `.click()` via Apple Events did not trigger the React
Authorize button; a real coordinate click (activate Chrome + click in ONE command,
because VS Code steals focus back between commands) is what worked.

Why the old chain kept breaking: the MBP harvester only runs while the laptop is awake,
and its boot-time run can harvest a token-less husk before interactive Claude refreshes
the Keychain. Related: [[claude-p-auth-keychain]], [[claude-p-keychain-harvest]].
