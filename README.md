# claude-p-wrapper

Drop-in wrapper for `claude -p` (the non-interactive Claude Code CLI). Every call is logged to `~/apps/cc/logs/claude-p-usage.log` as JSON lines so we can audit which process is spending how many calls on which model. Fires two-tier Gmail alerts at 100 and 400 calls per hour and suppresses further calls after the hard cap to protect the Max plan allowance.
