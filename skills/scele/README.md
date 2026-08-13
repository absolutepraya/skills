# scele

A Bash 4+ CLI and agent skill for Fasilkom UI's SCELE Moodle LMS.

## Install

```bash
npx skills add absolutepraya/skills --skill scele
```

## Setup

```bash
~/.claude/skills/scele/bin/scele init
```

Set `SCELE_USERNAME` and `SCELE_PASSWORD` in your environment or `~/.secrets`. Then edit:

- `~/.config/scele/course-profile.json`: active term, configured course aliases, numeric IDs, exact SCELE shortnames, task prefixes, and optional course metadata.
- `~/.config/scele/profile.sh`: optional class filtering, user identity fields, and Google Sheet aliases.

Validate the profile and inspect enrollment:

```bash
source ~/.claude/skills/scele/bin/course-profile.sh
validate_course_profile
~/.claude/skills/scele/bin/scele courses
```

The course profile is the single semester-specific input. Do not modify SKILL.md or `bin/scele` during semester rollover.

## Common commands

```bash
scele deadlines
scele content <alias-or-id>
scele submissions <alias-or-id>
scele announcements <alias-or-id>
scele assignment <cmid>
scele status <cmid>
```

See [SKILL.md](./SKILL.md) for the complete command reference, safety rules, and deterministic Todoist deduplication contract.
