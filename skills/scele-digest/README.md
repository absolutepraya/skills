# scele-digest

Companion to the [`scele`](../scele) skill. Builds a daily one-message digest of:

- Upcoming SCELE assignment deadlines (next 14 days)
- New SCELE announcements per course
- Class-chat activity from configured Telegram groups (last 24h)
- Course-related Todoist tasks
- Anything new auto-added to Todoist this run

Posts as a single Discord message with structured embeds (orange-family gradient). Designed to run unattended on a cron schedule.

## Install

```bash
npx skills add absolutepraya/skills/scele-digest
```

The CLI drops the skill into your agent's skill dir (`~/.claude/skills/scele-digest/` for Claude Code, similar paths for other agents).

## Setup

### 1. Run the init script

```bash
~/.claude/skills/scele-digest/bin/init
```

This does three things in one shot:

1. Seeds `~/.config/scele-digest/config.yaml` and `~/.config/scele-digest/telegram.env` from the bundled templates (won't overwrite if they already exist).
2. Creates a Python venv at `<skill-dir>/.venv` and `pip install`s the deps: `pyyaml requests telethon python-dotenv`.
3. Patches the shebangs of `bin/send-digest` and `bin/tg-window` to point at that venv, so your agent can invoke them directly.

If you'd rather manage the venv yourself, run `bin/init --no-venv`.

### 2. Fill in `~/.config/scele-digest/config.yaml`

Minimum required: `semester`, at least one entry in `courses`, and a Discord destination (either `discord.webhook_url` or `discord.channel_id` + a bot token via env var).

```yaml
semester:
  term: genap
  year: "2025/2026"

courses:
  - abbrev: SOMECOURSE
    full_name: "Some Course Full Name"
    telegram_group: "Class Telegram Chat Title"
    lab_team: "Your Team Name"
    lecturers: ["LecturerFirstName"]

discord:
  webhook_url: "https://discord.com/api/webhooks/..."   # easiest
```

See `templates/config.yaml.example` for the full schema with inline docs.

### 3. (Optional) Telegram credentials

If you want the digest to read your class-chat Telegram groups, set `telegram.enabled: true` in config.yaml and fill in `~/.config/scele-digest/telegram.env` with API ID, API hash, and a Telethon session string. The comments inside that file include the one-liner for generating a session string using the venv `bin/init` just made for you.

### 4. (Optional) Todoist integration

If you want new deadlines auto-added as Todoist tasks, set `todoist.enabled: true` and put your Todoist project ID in config.yaml. Requires a Todoist MCP server wired into your agent — without it the skill will skip steps 6 and 7 (or fail soft, depending on the agent).

## Verify the install (smoke test)

Before depending on the daily run, sanity-check end-to-end with a minimal dry-run:

```bash
echo '{"run_date_display":"smoke test","upcoming_deadlines":[],"health":{}}' \
  | ~/.claude/skills/scele-digest/bin/send-digest --dry-run
```

Expected output:

```
OK: wrote /tmp/scele-digest-preview.json
    embeds: 1
```

Then a live test post (uses real Discord but harmless content):

```bash
echo '{"run_date_display":"smoke test","upcoming_deadlines":[],"health":{}}' \
  | ~/.claude/skills/scele-digest/bin/send-digest
```

Expected output: `OK: posted <message_id>` — and a single Discord message lands in your configured channel/webhook with one "Upcoming (14 days)" embed that says "clear horizon — nothing due in the next 14 days." Delete it from Discord after; it's just a probe.

## Running

Manually from your agent:

```
"run scele-digest"            # full live run
"run scele-digest --dry-run"  # render + write /tmp/scele-digest-preview.json, no post, no mutation
```

On a cron schedule — wire whatever scheduler you use. The skill itself just needs to be invoked by your agent at the scheduled time. Two patterns:

**Claude Code** (system cron invokes the CLI):
```
0 7 * * *  /home/you/.local/bin/claude -p "/scele-digest" --dangerously-skip-permissions >> ~/.logs/scele-digest.log 2>&1
```

**Cursor / Codex / other agents:** check your agent's docs for cron / scheduled-task support. The invocation prompt is the same shape: tell the agent to run the `scele-digest` skill.

## Discord delivery

Two modes, both supported. Pick one in `config.yaml`:

### Webhook (simpler — recommended for first install)

1. In Discord, right-click your target channel → **Edit Channel** → **Integrations** → **Webhooks** → **New Webhook**.
2. Name it whatever you like, optionally set an avatar.
3. **Copy Webhook URL** and paste into `config.yaml` under `discord.webhook_url`.

Posts appear as the webhook's display name.

### Bot (richer)

1. Register an application at https://discord.com/developers → **New Application** → enable **Bot** → **Reset Token** and copy the token somewhere secure.
2. Under **OAuth2 → URL Generator**: tick `bot` scope, then permissions `View Channel` + `Send Messages` + `Embed Links`. Open the generated URL and authorize the bot into your guild.
3. In Discord with **Developer Mode** enabled (Settings → Advanced), right-click your target channel → **Copy ID**. Paste into `config.yaml` under `discord.channel_id` (as a string).
4. Export the token in the env var named by `discord.bot_token_env` (default: `DISCORD_BOT_TOKEN`). Make sure that var is set whenever your agent invokes the skill.

If both webhook and bot are configured, webhook wins.

## What the message looks like

A single Discord message with:

- Header line: bold title + new-deadline/new-todo counts.
- Health subtext line: per-source `ok` / `fail` / `—` flags.
- Up to 5 embeds, each in a stripe of the orange-family gradient (`FF5F00 → FF8C00 → FFC300 → FFD400`):
  - Upcoming deadlines (14-day window)
  - New tasks added to Todoist this run
  - Course announcements + AI summary
  - Telegram class-chat summary (one section per course)
  - All current course tasks in Todoist (grouped for repetitive series)

Embeds are omitted when their underlying data is empty — so dry days produce a short message.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ERR: config not found at ~/.config/scele-digest/config.yaml` | First-time install, didn't run `bin/init` | Run `~/.claude/skills/scele-digest/bin/init`. |
| `ModuleNotFoundError: No module named 'yaml'` (or `requests` / `telethon`) | Shebang resolved to a python without the deps | Re-run `bin/init` (it'll patch the shebangs to the venv that has the deps). |
| `ERR: discord post failed: Discord 401: ... 401: Unauthorized` | Bot token wrong or unset | Check `echo $DISCORD_BOT_TOKEN` is non-empty, regenerate the bot token if needed. |
| `ERR: discord post failed: Discord 403: ... Missing Access` | Bot not in the guild, or missing channel perms | Re-run the OAuth invite URL, make sure View Channel + Send Messages + Embed Links are granted on the target channel. |
| `ERR: discord post failed: Discord 404: Unknown Channel` | `discord.channel_id` typo or bot not in that guild | Verify the channel ID with right-click → Copy ID. |
| `ERR: discord post failed: Discord webhook 401` | Webhook URL was deleted/regenerated | Make a new webhook, paste the new URL into config. |
| `tg-window` returns `{"error": "missing TELEGRAM_API_ID ...", ...}` | `telegram.env` empty or `telegram.env_file` path wrong | Fill in `~/.config/scele-digest/telegram.env` (see comments). |
| `tg-window` returns `{"error": "could not resolve chat: ..."}` | Chat title doesn't match any of your dialogs | Open Telegram on your phone, copy the exact group title (case insensitive but characters must match), paste into `telegram_group` in config.yaml. |
| `tg-window` returns `{"error": "Telegram session not authorized — regenerate ..."}` | Session string expired (rare — usually only after manual logout) | Regenerate using the one-liner in `telegram.env.example`. |
| Embed shows multiple `**ABBREV**:` lines for the same course | Older agent / didn't follow the "one section per course" rule | Re-run; SKILL.md step 5b now spells this out. If it persists, file an issue. |

## License

MIT
