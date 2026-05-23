# SCELE Quiz API — Session Notes (May 2026)

## Context

ProgPar (course ID 4157) has quizzes that do NOT appear in `scele events` because that command only
surfaces `modulename == "assign"` items from `core_calendar_get_calendar_upcoming_view`. Quizzes are
a separate module type and need `mod_quiz_get_quizzes_by_courses` to discover.

## Key discovery

Quiz **"quiz gpu memory performance - coalescing"** (quiz ID 9933, coursemodule 213588):
- Was announced by pak Heru in Telegram group "progpar 26 UI" the day before
- Was NOT visible in `scele events` or `scele deadlines`
- Had to be discovered via `mod_quiz_get_quizzes_by_courses` API call
- timeopen: 1777857300 = 2026-05-04 08:15 WIB (that particular week — future quizzes get new IDs)

## Observation: quizzes created last-minute

All ProgPar quizzes observed were created shortly before class. Don't expect them to appear the night
before — poll during the class window (08:00–09:45 WIB) at 3-minute intervals.

## ProgPar quiz history (Genap 2025/2026)

| ID   | Name                                            | Open                  | Timelimit |
|------|-------------------------------------------------|-----------------------|-----------|
| 9856 | UTS pilihan ganda                               | 2026-04-08 16:00 WIB  | 60 min    |
| 9874 | pengantar GPU                                   | 2026-04-15 09:00 WIB  | 5 min     |
| 9915 | gpu-thread                                      | 2026-04-27 08:19 WIB  | 5 min     |
| 9933 | quiz gpu memory performance - coalescing, 08.15 | 2026-05-04 08:15 WIB  | 10 min    |

All are pilihan ganda (MCQ) so far. Timelimit short (5–10 min), attempts = 1.

## Full auto-attempt flow (confirmed possible via API)

1. `mod_quiz_get_quizzes_by_courses` — discover new quiz IDs
2. `mod_quiz_get_attempt_access_information` — check if accessible
3. `mod_quiz_start_attempt` — returns `attempt.id`
4. `mod_quiz_get_attempt_data` — returns question HTML + slot info
5. Parse questions (HTML scraping or AI reasoning on the text)
6. `mod_quiz_process_attempt` — save answers by slot
7. `mod_quiz_finish_attempt` — submit

Token obtained via: `POST https://scele.cs.ui.ac.id/login/token.php` with `service=moodle_mobile_app`

## Response when quiz not open

`mod_quiz_start_attempt` returns:
```json
{"attempt": [], "warnings": [{"warningcode": "1", "message": "This quiz is not currently available"}]}
```
This is normal. Poll until warning disappears.
