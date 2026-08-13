---
name: scele
description: Fetch courses, deadlines, materials, announcements, grades, submissions, and forum threads from SCELE, the Fasilkom UI Moodle LMS. Use for tugas, deadline, matkul, jadwal, assignments, grades, or SCELE-related requests.
user-invocable: true
---

# SCELE academic workflow

Use the bundled CLI for SCELE data. Resolve a named course through the active course profile. Do not infer a course from historical examples or a fuzzy name match.

## First-time setup

1. Export `SCELE_USERNAME` and `SCELE_PASSWORD` through your shell environment or `~/.secrets`.
2. Run `~/.claude/skills/scele/bin/scele init`.
3. Edit `~/.config/scele/course-profile.json` with the current term and every active course.
4. Optionally edit `~/.config/scele/profile.sh` with your class and identity metadata.
5. Run `scele courses`, then inspect a configured alias with `scele content <alias>`.

A course profile entry contains a stable command alias, numeric SCELE course ID, exact SCELE shortname, display name, Todoist prefix, and optional Telegram, team, lecturer, or migration-alias metadata. Update this one profile during semester rollover. Validate it before depending on course-specific behavior:

```bash
source ~/.claude/skills/scele/bin/course-profile.sh
validate_course_profile
```

## Commands

```bash
scele events
scele deadlines
scele courses
scele content <alias-or-id> [section]
scele download <alias-or-id> <filename>
scele submissions <alias-or-id>
scele announcements <alias-or-id>
scele grades <alias-or-id>
scele assignment <cmid>
scele posts <discussion-id>
scele page <cmid>
scele status <cmid>
scele submit <cmid> <file>
scele bind <out.pdf> <in.pdf>...
scele sheet <alias-or-id> [npm]
scele me
```

Numeric SCELE course IDs are permitted for a one-off inspection. They do not make a course active for scheduled collection.

## Operating rules

- Read an assignment's full details with `assignment <cmid>` before proposing work or submission. Titles alone omit file limits, naming rules, and instructions.
- Use `submissions <alias>` for every pending slot and its status. Use `announcements <alias>` for new course news, then `posts <discussion-id>` for replies.
- `events` and `deadlines` list assignments only. Quiz modules require their own Moodle API endpoint.
- Class filtering is optional. An empty `USER_CLASS` must not suppress class-labelled items.
- Ask before any external side effect, including submission, Todoist task creation, Telegram posting, email, or file upload.
- Do not disable TLS certificate verification to work around SCELE outages.

## Todoist identity matching

For a scheduled digest, never deduplicate by fuzzy title similarity. Give `bin/todoist-dedup` all active Todoist tasks and new SCELE deadlines. It matches in order: exact assignment URL in a task description, explicit `todoist_aliases` for a deadline module ID, then a normalized title with the configured prefix. Only its `unmatched` CMIDs are eligible for task creation.

The helper reads JSON from stdin and writes JSON only. It makes no network calls and mutates no task, SCELE, or state data.

## References

See `references/quiz-api-flow.md` for Moodle quiz API behavior and current endpoint examples.
