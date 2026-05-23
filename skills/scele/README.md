# scele

Agent skill for Fasilkom UI's [SCELE](https://scele.cs.ui.ac.id) Moodle LMS. Lets your agent fetch upcoming deadlines, browse course materials, read assignment specs, post and verify forum threads, submit assignments, and bind multi-PDF deliverables — directly against the SCELE Moodle Web Services API.

## Install

```bash
npx skills add absolutepraya/skills/scele
```

The CLI drops it into `~/.claude/skills/scele/` (or wherever your agent looks).

## Setup

Bash 4+, `curl`, and `jq` are required. On macOS: `brew install bash jq`.

```bash
# 1. SCELE creds in ~/.secrets (sourced by ~/.zshrc or similar)
echo 'export SCELE_USERNAME="2306xxxxxx"' >> ~/.secrets
echo 'export SCELE_PASSWORD="..."'        >> ~/.secrets

# 2. Create per-user profile from template
~/.claude/skills/scele/bin/scele init

# 3. Edit ~/.config/scele/profile.sh with your NPM, kelas, dosen,
#    and your enrolled COURSE_IDS this semester.

# 4. Verify
~/.claude/skills/scele/bin/scele me
~/.claude/skills/scele/bin/scele courses
```

## Commands

| Command | Purpose |
|---|---|
| `scele events` / `deadlines` | List upcoming events / assignment deadlines (filtered to your kelas) |
| `scele courses` | List enrolled courses with IDs |
| `scele content <course> [section]` | Browse course materials |
| `scele download <course> <filename>` | Download a course resource |
| `scele submit <cmid> <file>` | Upload + submit to an assignment slot |
| `scele status <cmid>` | Check submission status |
| `scele assignment <cmid>` | Read full assignment intro, naming, file limits, deadlines |
| `scele submissions <course>` | All assignments + per-assignment submission status |
| `scele grades <course>` | Show your grades |
| `scele announcements <course>` | Recent course announcements |
| `scele posts <discussion_id>` | List every post in a forum thread |
| `scele page <cmid>` | Read body text of a page/label/module |
| `scele bind <out.pdf> <in.pdf>...` | Concat PDFs (for "1 PDF only" submission slots) |
| `scele sheet <alias> [lookup]` | Fetch a known Google Sheet as CSV |
| `scele me` | Print your profile |
| `scele init` | First-time profile setup |

See [`SKILL.md`](./SKILL.md) for the full workflow guide (deadline cross-referencing with Telegram, Nextcloud, Todoist; Kerja Praktik primer; Quiz API endpoints; common laporan mistakes; etc.).

## Why bash?

The whole skill is one bash script. No Node, no Python — just `curl` and `jq` against the Moodle Web Services REST API. macOS ships bash 3.2 at `/bin/bash`; the script self-re-execs under Homebrew's bash 5 at `/opt/homebrew/bin/bash` automatically when needed.

## License

MIT
