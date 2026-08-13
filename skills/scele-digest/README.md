# scele-digest

Companion to [`scele`](../scele). It creates a daily Discord digest from active SCELE courses, optional class-chat activity, and Todoist tasks.

## Install

```bash
npx skills add absolutepraya/skills --skill scele
npx skills add absolutepraya/skills --skill scele-digest
~/.claude/skills/scele/bin/scele init
~/.claude/skills/scele-digest/bin/init
```

## Configure

1. Edit `~/.config/scele/course-profile.json`. It defines every current course, SCELE ID, exact shortname, Todoist prefix, and optional Telegram data.
2. Edit `~/.config/scele-digest/config.yaml` with a Discord webhook or a bot channel ID and environment variable name.
3. Optionally configure `~/.config/scele-digest/telegram.env`.

The shared course profile is the only semester-specific course input. Do not edit the skill instructions or renderer when courses change.

## Verify without side effects

```bash
echo '{"run_date_display":"smoke test","new_items":{"deadlines":[],"announcements":[]},"todos_added":[],"upcoming_deadlines":[],"announcements_all_new":[],"telegram_messages":[],"todos_all_courses":[],"health":{"scele":true,"telegram":true,"todoist":true}}' \
  | ~/.claude/skills/scele-digest/bin/send-digest --dry-run
```

A live run must validate the exact payload first, then post only with an explicitly configured delivery destination.

See [SKILL.md](./SKILL.md) for collection order, failure boundaries, and deterministic Todoist deduplication.
