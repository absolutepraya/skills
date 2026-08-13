# Runtime pitfalls observed in production runs

## Deadline fallback and class filtering

When `scele deadlines` is available, treat it as the source of truth for deadline inclusion because it already applies the user-specific class filter.

Observed pitfall: a raw REST fallback via `core_calendar_get_calendar_upcoming_view` can surface assignment events for the right course but the wrong section.

Safe rule:
- Use CLI deadlines first for the final digest list.
- Use REST deadline data only to recover missing structured fields if the CLI transcript is too thin.
- If you must build deadlines from REST alone, explicitly reimplement class filtering instead of trusting all returned assignment events.

## Announcement seen IDs

`state/seen.json` may contain numeric Moodle forum discussion IDs directly, not only hashes.

Safe rule:
- Prefer the numeric discussion ID whenever the API exposes it.
- Keep existing numeric IDs as-is when reading or pruning state.
- Use a hash fallback only when the API truly does not expose a stable ID.

## Telegram MCP inconsistency

Observed pitfall: `get_chat` metadata can report a newer last message than `get_messages`, `list_messages`, or text search are able to retrieve. In one production run, this led to a digest summary referencing a bot's status notice (`PorosAiccountantBot`) that did not actually appear in the chat's last-24h history — the model picked up the metadata field and treated it as content.

This is why the skill bundles `bin/tg-window`: a deterministic Telethon helper that iterates real message history, applies mechanical filters (bot senders, system actions, empty messages), and returns clean structured JSON. The Telegram MCP is explicitly not used as a fallback for the 24h window.

Safe rule:
- Use `bin/tg-window` for the 24h window. Don't fall back to Telegram MCP `get_chat`.
- If the helper returns zero messages, accept that as "no course activity" — set `telegram_ai_summary` to `null` and omit the embed.

## Media health semantics

Do not set `health.media_read` to `false` just because there were no recent media attachments to inspect.

Safe rule:
- `true` if at least one attachment was attempted and all attempted reads succeeded.
- `false` if any attempted media download or read failed.
- `null` if there was no media to read, or nothing was attempted.

## Persisting seen.json safely

If you rewrite `state/seen.json`, re-read the whole file first.

Observed pitfall: overwriting after only a paginated or partial read can trigger safety warnings and risks dropping entries.

Safe rule:
- Load the full file before writing.
- Prune in memory.
- Persist only after the renderer reports success in live mode.

## Don't mention filtered-out content

If a Telegram chat's 24h window contained only bot notices or chitchat that was filtered out, omit that course from the AI summary entirely. Do NOT say things like "the group was quiet except for a bot notice". The skipped content does not exist for the summary — a course that doesn't appear means "no course activity", which is the correct signal.
