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

The CLI drops it into `~/.claude/skills/scele-digest/` (or wherever your agent looks).

## Setup

### 1. Python deps

```bash
python3 -m venv ~/.claude/skills/scele-digest/.venv
~/.claude/skills/scele-digest/.venv/bin/pip install pyyaml requests telethon python-dotenv
```

Update the shebangs in `bin/send-digest` and `bin/tg-window` to point at this venv, or symlink `python3` accordingly.

### 2. Seed the user config

```bash
~/.claude/skills/scele-digest/bin/init
```

Creates `~/.config/scele-digest/config.yaml` and `~/.config/scele-digest/telegram.env` from the bundled templates.

### 3. Fill in `~/.config/scele-digest/config.yaml`

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

### 4. (Optional) Telegram credentials

If you want the digest to read your class-chat Telegram groups, set `telegram.enabled: true` in config.yaml and fill in `~/.config/scele-digest/telegram.env` with API ID, API hash, and a Telethon session string. See the comments in `templates/telegram.env.example` for the one-liner to generate a session string.

### 5. (Optional) Todoist integration

If you want new deadlines auto-added as Todoist tasks, set `todoist.enabled: true` and put your Todoist project ID in config.yaml. Requires a Todoist MCP server wired into your agent.

## Running

Manually:

```bash
# Tell your agent: "run scele-digest"
# Or for a sanity check that doesn't post or mutate state:
# "run scele-digest --dry-run"
```

On a cron schedule — wire whatever scheduler you use to invoke the skill. The agent invocation is the same as a manual run; `cron` just calls it on a timer. Example using Claude Code's built-in cron at 7am daily:

```
0 7 * * *  /home/you/.local/bin/claude -p "/scele-digest" --dangerously-skip-permissions
```

## Discord delivery

Two modes, both supported. Pick one in `config.yaml`:

- **Webhook** (`discord.webhook_url`): simpler. Create a webhook on your target channel (Edit Channel → Integrations → Webhooks → New). Paste the URL. Posts as the webhook's display name.

- **Bot** (`discord.channel_id` + token env var): richer. Register an app at https://discord.com/developers, invite the bot to your guild with Send Messages permission on the target channel, copy the channel's numeric ID (right-click → Copy ID with Developer Mode on), and export the bot token in the env var named by `discord.bot_token_env` (default: `DISCORD_BOT_TOKEN`).

If both are set, webhook wins.

## What the message looks like

A single Discord message with:

- Header line: bold title + new-deadline/new-todo counts.
- Health subtext line: per-source `ok` / `fail` / `—` flags.
- Up to 5 embeds, each in a stripe of the orange-family gradient:
  - Upcoming deadlines (14-day window)
  - New tasks added to Todoist this run
  - Course announcements + AI summary
  - Telegram class-chat summary (tagged per course)
  - All current course tasks in Todoist (grouped for repetitive series)

Embeds are omitted when their underlying data is empty — so dry days produce a short message.

## License

MIT
