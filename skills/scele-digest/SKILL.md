---
name: scele-digest
description: Fire-and-forget daily SCELE digest — fetches deadlines and announcements from SCELE (Fasilkom UI Moodle), inspects recent class-chat activity on Telegram, deduplicates against Todoist, and posts a structured digest to a Discord channel via webhook or bot. Designed to run unattended on a cron schedule. Use this skill whenever the user says "run scele-digest", mentions the daily digest, wants to test it manually, or asks to preview (dry-run). Do NOT use for interactive SCELE browsing — that's the `scele` skill.
user-invocable: true
---

# SCELE Digest — Daily Unattended Discord Brief

Companion to the [`scele`](../scele) skill. Builds a daily one-message digest of:

- Upcoming SCELE assignment deadlines (next 14 days)
- New SCELE announcements per course
- Class-chat activity from configured Telegram groups (last 24h)
- Course-related Todoist tasks
- Anything new auto-added to Todoist this run

Posts as a single Discord message with structured embeds. Designed to run unattended on a cron schedule (`0 7 * * *` works well) — never asks the user questions, flags partial failures in a run-health line at the top of the message.

## When Invoked

Two modes:

- `scele-digest` → full run: fetch, add tasks, post to Discord
- `scele-digest --dry-run` → fetch, render payload to `/tmp/scele-digest-preview.json`, do NOT add tasks, do NOT post. Useful for template development and sanity checks.

## Prerequisites

- `scele` skill installed and configured (used for fetching SCELE data).
- Python 3.10+ with a venv at `<skill-dir>/.venv` containing: `pyyaml`, `requests`, `telethon`, `python-dotenv`.
- `bin/init` has been run — config exists at `~/.config/scele-digest/config.yaml`.
- Discord destination configured: a webhook URL or a bot token + channel ID.
- (Optional) Telegram session credentials at `~/.config/scele-digest/telegram.env`.
- (Optional) Todoist MCP server and a Todoist project ID for auto-adding tasks.

## Workflow

Follow these steps in order. Wrap each data-source call in try/except — on failure, record the source as failed in the run-health dict, log the error to stderr, and continue with partial data.

### Step 0: Load configuration

Read `~/.config/scele-digest/config.yaml`. This is the per-user, per-semester source of truth — never hardcode the values it carries. Structure:

```yaml
semester:
  term: gasal | genap
  year: "YYYY/YYYY"
courses:
  - abbrev: <COURSE_ABBREV>
    full_name: <descriptive name>
    telegram_group: <chat title> | null
    lab_team: <team name> | null
    lecturers: [<name>, <name>, ...]   # may be []
discord:
  webhook_url: <url> | null
  channel_id: <id> | null
  bot_token_env: <env var name>
telegram:
  enabled: true | false
  env_file: <path>
todoist:
  enabled: true | false
  project_id: <id> | null
```

Derive these working sets and use them throughout:

- `enrolled_abbrevs = [c.abbrev for c in courses]` — the SCELE/Todoist filter.
- `telegram_targets = [(c.abbrev, c.telegram_group) for c in courses if c.telegram_group]` — chats to fetch in Step 5 (only matters when `telegram.enabled`).
- `lab_teams = {c.abbrev: c.lab_team for c in courses if c.lab_team}` — per-course team highlighting.
- `lecturers_by_course = {c.abbrev: c.lecturers for c in courses}` — per-course name filters.

If `config.yaml` is missing or malformed, abort with a clear error rather than guessing.

### Step 1: Load state

Read `<skill-dir>/state/seen.json`. Buckets:
- `deadlines`: `{cmid_or_event_id: first-shown-ISO-timestamp}`
- `announcements`: `{post_id: first-shown-ISO-timestamp}`

If the file doesn't exist yet, treat as empty: `{"deadlines": {}, "announcements": {}}`. Prune entries older than 30 days before using.

### Step 2: Fetch enrolled courses

Run `scele courses` to get current enrollment. Parse abbreviations and keep only those in `enrolled_abbrevs` (from Step 0). Ignore any SCELE course that doesn't map to a config abbreviation — that's the safety net against stale courses from prior semesters still appearing in the API.

If CLI output is truncated, fall back to direct SCELE REST calls. The `scele` skill's references doc covers this.

### Step 3: Fetch deadlines (all courses)

Run `scele deadlines`. Filter to items due within **14 days** from now. For each, record: `{abbrev, title, due_iso, scele_url, cmid, is_new: bool}`.

`is_new = True` if `cmid` is NOT in `seen.deadlines`. Add new IDs to `seen.deadlines` with today's timestamp.

Prefer the CLI as the source of truth — it already applies the user's class filter. Raw REST fallback can surface assignments from the wrong section.

### Step 4: Fetch announcements (per course)

For each enrolled abbrev, run `scele announcements <ABBREV>`. For each announcement, determine a stable ID (forum post ID, or hash of `url + title` as fallback). Include only announcements NOT in `seen.announcements`. Add shown IDs to `seen.announcements`.

Record: `{abbrev, title, posted_iso, url, body_snippet}` (first ~200 chars of body for preview).

Prefer the numeric Moodle discussion ID as the stable announcement ID whenever REST exposes it.

### Step 4b: Draft AI Summary for course announcements

Synthesize an `announcements_ai_summary` string covering 4–8 lines:

- **What's happening across courses today.** Group by abbrev.
- **Anything the user needs to do** — new deliverables hidden in announcements, deadlines not already in Step 3.
- **Per-course lab team mentions.** For each course with a `lab_teams[abbrev]` entry, if that team is mentioned in the announcement, surface it. Don't cross-tag — a team belongs to one course.
- **Lecturer directives** — any author whose name matches a substring in `lecturers_by_course[abbrev]` for the relevant course.

Skip noise. If there were no announcements, set `announcements_ai_summary` to `null`.

The string can include simple HTML (`<strong>`, `<br>`); the renderer converts to Discord markdown.

### Step 5: Fetch Telegram course groups (last 24h)

If `telegram.enabled` is `false` or `telegram_targets` is empty, skip this step entirely — set `telegram_messages: []` and `telegram_ai_summary: null`.

Otherwise, for each entry in `telegram_targets`, run the deterministic helper:

```bash
<skill-dir>/bin/tg-window --chat "<group title>" --hours 24
```

The helper connects via Telethon (using the session in `telegram.env_file`) and applies mechanical filters (bot senders, system/action messages, empty messages) so you don't have to slice a long `get_history` dump yourself. The output is a JSON array of message dicts.

**Scope is exactly the chats named in `telegram_targets`** — one per course that has `telegram_group` set. Do not look at any other chat, channel, DM, or saved-messages. Do not call any Telegram MCP tools as a fallback — they have shown stale `get_chat` "last message" metadata in past runs.

**On top of the helper's mechanical filtering, also drop these by semantic judgment** before recording into `telegram_messages`:

- Pure social chitchat with no academic content ("ok", "siap", stickers/emoji-only reactions, off-topic memes).
- Messages that *look* like content but are clearly off-topic.

Keep:

- Messages from senders whose name matches a substring in `lecturers_by_course[abbrev]` for the chat's course (case-insensitive).
- Student messages about assignments, deadlines, lab work, project submissions, group coordination, technical questions.
- Any message mentioning `lab_teams[abbrev]`, if set.
- Media (photos, PDFs, slides, screenshots) tied to coursework.

For each kept message, tag it with the source course and record into `telegram_messages` as `{course, sender_name, timestamp_iso, text, has_media, media_hint, url}`. The `course` field is the abbrev of the group it came from.

Note: for basic groups, `url` is empty — Telegram doesn't expose per-message deep links there.

To debug, re-run with `--include-dropped`.

### Step 5b: Read media + draft AI Summary

For each KEPT message with `has_media == True`:

1. Attempt to download the file via the Telegram MCP (`mcp__telegram-mcp__download_media` or equivalent — varies by server). Save to `/tmp/scele-digest-media/`.
2. If image/photo/sticker: inspect directly with vision capabilities. Extract any text on slides/screenshots.
3. If document (`.pdf`, `.docx`, `.pptx`, `.xlsx`, `.txt`): read its content via the appropriate skill.
4. If voice/video: skip — note as "voice note from <sender>" so the user knows to listen manually.
5. If download fails: record in run health and skip — non-fatal.

After media is read, synthesize **one** combined `telegram_ai_summary` string covering all courses with activity. Aim for 4–10 lines total.

**Exactly one section per course.** Even if there are several distinct topics from a course's chat, fold them into a single course block — don't emit `<strong>ABBREV</strong>:` repeatedly. Format:

```
<strong>ABBREV</strong>
- topic 1
- topic 2
- topic 3
```

Bold course header on its own line; sub-points as dash bullets below. Use `<br>` for line breaks if needed. If a course has only one point, inline it as `<strong>ABBREV</strong>: <point>`. Either way, one course = one section.

Per course with kept messages, the section should cover:

- What is the group actually doing right now?
- What does the user need to do?
- Anything from `lab_teams[abbrev]` (skip the bullet if that course has no team)?
- Critical lecturer messages from senders matching `lecturers_by_course[abbrev]`?

**Do not mention filtered-out content.** If a course's 24h window had only bot notices or chitchat, omit that course from the summary entirely. A course that doesn't appear means "no course activity" — the correct signal.

If `telegram_messages` is empty after fetching, set `telegram_ai_summary` to `null`. The renderer will omit the Telegram embed.

### Step 6: Fetch Todoist — existing course tasks

If `todoist.enabled` is `false`, skip this step and set `todos_all_courses: []`.

Otherwise, use Todoist MCP `get_tasks` with `project_id` from `config.todoist.project_id`. Filter to tasks whose title starts with `<abbrev> — ` for any abbrev in `enrolled_abbrevs`.

Record all for the "All course tasks" embed, with **grouping**: collapse repetitive series into one entry so the embed isn't flooded. When ≥3 tasks share a course abbrev + a recognizable series label, group them into a single entry with `count` ≥ 3 and `earliest_due_iso`/`latest_due_iso`.

### Step 7: Auto-add new deadlines to Todoist

If `todoist.enabled` is `false`, skip.

Otherwise, for each deadline in Step 3 where `is_new == True` AND no existing Todoist task has the same title:

- `content`: `<abbrev> — <title>`
- `description`: short summary + `\n\n<scele_url>`
- `priority`: `4`
- `due_datetime`: SCELE due time **minus 12 hours**, ISO 8601
- `project_id`: `config.todoist.project_id`

Log each added task into `todos_added` for the corresponding embed.

### Step 8: Build JSON payload

Assemble:

```json
{
  "run_date_iso": "YYYY-MM-DD",
  "run_date_display": "Wkd, DD Mon",
  "new_items": {
    "deadlines": [...],
    "announcements": [...]
  },
  "todos_added": [...],
  "upcoming_deadlines": [...],
  "announcements_all_new": [...],
  "announcements_ai_summary": "..." | null,
  "telegram_messages": [{"course": "...", ...}],
  "telegram_ai_summary": "..." | null,
  "todos_all_courses": [...],
  "health": {"scele": true, "telegram": true, "todoist": true, "discord": null, "media_read": null}
}
```

Notes on the shape:

- `urgency` per deadline: `today` if due == run_date, `tomorrow` if +1, `this_week` if within 7, else `next_week`. Renderer uses this for color/labeling.
- `health.discord` stays `null` until the renderer attempts to post.
- `health.media_read` — `true` only if ≥1 media attempt and all succeeded, `false` if any attempt failed, `null` if no media was present or nothing was attempted. **Do NOT set to `false` when no media was present** — use `null`.
- `telegram_messages[*].course` is the abbrev for which chat the message came from.

### Step 9: Pipe to renderer

```bash
<skill-dir>/bin/send-digest [--dry-run]
```

The renderer reads `discord` from `config.yaml` and either:

- POSTs to `discord.webhook_url` if set, or
- POSTs as a bot to `discord.channel_id` using the token from the env var named in `discord.bot_token_env`.

Webhook wins if both are configured. The renderer prints `OK: posted <message_id>` on success and exits non-zero with `ERR: ...` on stderr otherwise.

### Step 10: Persist state

Write the updated `seen.json` back **only after** the renderer reports success in live mode. For `--dry-run`, do NOT persist.

Before writing, re-read the full `seen.json` file instead of relying on a paginated or partial earlier read.

## References

- `references/runtime-pitfalls.md` — production notes on class filtering, numeric announcement IDs, Telegram MCP inconsistencies, media health semantics, and safe `seen.json` persistence.

## Files

- `config.yaml` (at `~/.config/scele-digest/config.yaml`) — per-user, per-semester configuration. Edit at semester rollover.
- `telegram.env` (at `~/.config/scele-digest/telegram.env`) — Telegram user-session credentials (only needed if `telegram.enabled: true`).
- `bin/send-digest` — Python renderer + Discord poster (supports webhook OR bot).
- `bin/tg-window` — Telethon helper that returns clean per-message JSON for a chat in a time window.
- `bin/init` — copies the templates into `~/.config/scele-digest/` on first install.
- `templates/config.yaml.example` — config scaffold.
- `templates/telegram.env.example` — env-var scaffold for Telegram credentials.
- `state/seen.json` — dedup index (gitignored, created on first run).

## Constants (intentionally stable)

- Discord API base: `https://discord.com/api/v10`
- Embed side-bar gradient (orange family, top→bottom): `FF5F00 → FF8C00 → FFC300 → FFD400`
- Max 10 embeds per Discord message; max 4096 chars per embed description.
