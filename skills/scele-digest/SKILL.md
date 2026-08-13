---
name: scele-digest
description: Run a daily SCELE digest that collects configured-course deadlines and announcements, optional class-chat activity, Todoist tasks, and posts a Discord summary. Use when asked to run, preview, or troubleshoot the scheduled SCELE digest.
user-invocable: true
---

# SCELE digest

This is an unattended workflow. It must collect deterministically, validate before posting, and never create duplicate Todoist tasks.

## Setup

Install and configure the sibling `scele` skill first. Its `~/.config/scele/course-profile.json` is the only active-course source. Configure Discord delivery in `~/.config/scele-digest/config.yaml`, and optionally Telegram credentials in `~/.config/scele-digest/telegram.env`.

## Run modes

- `/scele-digest`: collect, update eligible Todoist tasks, validate, and post.
- `/scele-digest --dry-run`: collect and render a preview only. Do not create a Todoist task or post to Discord.

## Required workflow

1. Validate the shared course profile before any course-specific work. Select configured course IDs only, and require each enrolled course's exact configured SCELE shortname before collecting it.
2. Fetch deadlines and announcements for those selected courses. Keep SCELE URLs and module IDs. An identity mismatch is unhealthy and must stop before Todoist, Discord, or state mutation.
3. Fetch Telegram only for configured `telegram_group` values. `null` is an intentional healthy skip.
4. Fetch all active Todoist tasks in the configured project. Give every new deadline plus the full task snapshot to `../scele/bin/todoist-dedup`.
5. Treat the helper output as authoritative. It matches exact SCELE assignment URL, then explicit profile alias, then a normalized prefixed title. Add tasks only for `unmatched` CMIDs. Do not retry title matching by judgment.
6. Build the payload and validate it through `bin/send-digest --dry-run` before a live post. Feed the exact validated JSON to the live renderer only after validation succeeds.
7. Preserve source health separately. Missing optional Telegram configuration is healthy. A failed required collection or identity check must not produce an apparently healthy live post.

## Todoist helper input

```json
{
  "profile_path": "~/.config/scele/course-profile.json",
  "deadlines": [{"cmid": 123, "title": "Assignment", "scele_url": "https://scele.cs.ui.ac.id/mod/assign/view.php?id=123", "todoist_prefix": "COURSE"}],
  "tasks": [{"content": "COURSE - Assignment", "description": "..."}]
}
```

The helper prints `{ "matched": [...], "unmatched": [...] }` and performs no network or state action.

## Safety

- Do not disable TLS verification.
- Do not treat a partial or stale payload as valid for posting.
- Do not create task, Discord, Telegram, email, or submission side effects in dry-run mode.
- Ask for explicit approval before enabling or changing a scheduler, destination, or posting cadence.
