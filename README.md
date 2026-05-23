# skills

Agent skills by [@absolutepraya](https://github.com/absolutepraya).

Install any of them with the [skills.sh](https://www.skills.sh) CLI:

```bash
npx skills add absolutepraya/skills/<skill-name>
```

## Available skills

| Skill | What it does | Install |
|---|---|---|
| [`scele`](./skills/scele) | CLI for Fasilkom UI's SCELE Moodle LMS — fetch deadlines, browse course materials, submit assignments, read forum threads, bind PDFs, etc. Bash 4+, requires SCELE creds. | `npx skills add absolutepraya/skills/scele` |

## Why a monorepo

Each skill in this repo is a self-contained directory under `skills/`, conforming to the [Anthropic Agent Skill](https://www.anthropic.com/news/agent-skills) format (`SKILL.md` + optional `bin/`, `scripts/`, `references/`, `templates/`). The skills CLI auto-discovers any directory containing a valid `SKILL.md`.

This layout means:
- One repo to clone for everything I publish.
- Sub-path installs (`<owner>/<repo>/<skill>`) work via the skills.sh CLI.
- Cross-skill helpers can be shared without polluting individual skill bundles.

## Contributing / forking

These skills target my own machine setup (macOS + Homebrew + dotfiles symlink farm into `~/.claude/skills`, `~/.config/opencode/skills`, etc.). Each skill ships its own per-user profile mechanism — read the skill's `SKILL.md` for setup steps.

## License

MIT — see [`LICENSE`](./LICENSE).
