#!/usr/bin/env bash
# claude-p auth heartbeat — proves the OAuth token still works.
#
# Runs on a schedule (every 30 min via launchd). Calls the claude-p wrapper
# with a trivial prompt. The wrapper's auth-failure detectors (CLI's
# "Not logged in" envelope, and API HTTP 401) handle email alerts — this
# script only has to *make* the call so those detectors get a chance to
# fire. We do not parse output here; we just log the exit code.
#
# Why this exists: 2026-05-18 a token started returning 401s at 4:28 PM,
# silently broke the auto-screenshot-renamer for 9 minutes before James
# noticed via the failure-quarantine email. With this heartbeat, we
# detect within 30 min of any token state change, regardless of whether
# a real workload happens to fire.

set -u

LOG_DIR="$HOME/apps/claude-p-wrapper/logs"
LOG_FILE="$LOG_DIR/heartbeat.log"
WRAPPER="$HOME/apps/claude-p-wrapper/claude-p"

mkdir -p "$LOG_DIR"

ts="$(date '+%Y-%m-%dT%H:%M:%S%z')"

# CLAUDE_P_PURPOSE tags this call in the usage log so it is easy to filter
# out of rate-limit accounting and analytics.
export CLAUDE_P_PURPOSE="auth-heartbeat"

# --max-turns 1 keeps the call cheap. Empty prompt is fine — we only need
# the CLI to authenticate, not produce a meaningful response.
out="$("$WRAPPER" --max-turns 1 "ok" 2>&1)"
rc=$?

# Trim to 200 chars so the log stays scannable.
trimmed="$(printf '%s' "$out" | tr '\n' ' ' | cut -c1-200)"

printf '[%s] rc=%d out=%q\n' "$ts" "$rc" "$trimmed" >> "$LOG_FILE"

exit "$rc"
