---
name: scele
description: Fetch upcoming events, deadlines, and courses from SCELE (Fasilkom UI Moodle LMS). Use when user asks about tugas, deadline, matkul, jadwal, assignments, or anything SCELE/kuliah-related.
user-invocable: true
---

# SCELE — Fasilkom UI Academic Workflow

Fetch deadlines and events from SCELE, cross-reference with Telegram and Nextcloud, offer to add tasks to Todoist, and optionally help complete assignments.

## When to Use

Use this skill when the user asks about:
- Assignments, tugas, homework, submissions
- Deadlines, due dates, tenggat waktu
- Courses, mata kuliah, matkul, kelas
- Calendar events, jadwal, schedule
- Anything related to SCELE, kuliah, or academic work at Fasilkom UI

Trigger phrases (Indonesian & English):
- "ada tugas apa?", "tugas apa aja?", "deadline kapan?"
- "cek SCELE", "liat SCELE", "buka SCELE"
- "what's due?", "upcoming deadlines", "my courses"
- Any mention of a specific course name (e.g., "pemrograman paralel", "proyek perangkat lunak")

## Setup (first time)

This skill is per-user — it needs to know your NPM, kelas, and which courses you're taking this semester.

```bash
# 1. Put SCELE creds somewhere your shell sources at startup (e.g., ~/.secrets)
echo 'export SCELE_USERNAME="2306xxxxxx"' >> ~/.secrets
echo 'export SCELE_PASSWORD="..."'        >> ~/.secrets

# 2. Create your profile from the bundled template
~/.claude/skills/scele/bin/scele init

# 3. Edit ~/.config/scele/profile.sh — fill in NPM, kelas, dosen,
#    and COURSE_IDS for the courses you're enrolled in this semester.

# 4. Verify
~/.claude/skills/scele/bin/scele me
~/.claude/skills/scele/bin/scele courses
```

Find a course's numeric ID by visiting it in SCELE: the URL `course/view.php?id=<num>` is the ID.

## Course Mapping

Course abbreviations and IDs are **user-configured** in `~/.config/scele/profile.sh`. The skill ships with no defaults — you set your own. Example:

```bash
COURSE_IDS=(
  [KP]=4126
  [PPL]=4125
  [ProgPar]=4157
  [MPPI]=4139
)
COURSE_NAMES=(
  [KP]="Kerja Praktik"
  [PPL]="Proyek Perangkat Lunak"
  [ProgPar]="Pemrograman Parallel"
  [MPPI]="Metodologi Penelitian"
)
```

Set `USER_CLASS` in the profile to filter deadlines to your kelas (e.g. `USER_CLASS="D"` hides "Kelas A/B/C/E/F" items).

Use the abbreviations in Todoist titles and folder names. Match SCELE output by partial course name (e.g., "Pemrograman Parallel" → ProgPar).

## Quiz API (Moodle WS)

> **Pitfall**: `scele events` dan `scele deadlines` **tidak menampilkan quiz**. Command itu hanya memfilter `modulename == "assign"`. Quiz butuh endpoint terpisah.

Quiz di ProgPar (dan matkul lain) seringkali baru dibuat di SCELE menit-menit sebelum kelas dimulai — jadi polling diperlukan untuk deteksi.

### Endpoints

```bash
# List all quizzes in a course
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_get_quizzes_by_courses&courseids[0]=<course_id>&moodlewsrestformat=json"

# Check access / attempt status
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_get_attempt_access_information&quizid=<quiz_id>&moodlewsrestformat=json"

# Start attempt
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_start_attempt&quizid=<quiz_id>&moodlewsrestformat=json"

# Get questions for an attempt
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_get_attempt_data&attemptid=<attempt_id>&page=0&moodlewsrestformat=json"

# Process (save) answers mid-attempt
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_process_attempt&attemptid=<attempt_id>&data[0][name]=q<slot>:1_answer&data[0][value]=<answer>&moodlewsrestformat=json"

# Finish and submit attempt
curl -s "https://scele.cs.ui.ac.id/webservice/rest/server.php" \
  -d "wstoken=$TOKEN&wsfunction=mod_quiz_finish_attempt&attemptid=<attempt_id>&timeup=0&moodlewsrestformat=json"
```

### Quiz fields to check after listing

```python
{
  "id": 9933,             # quiz ID
  "coursemodule": 213588, # cmid
  "name": "...",
  "timeopen": 1777857300, # unix timestamp, 0 = always open
  "timeclose": 1777862400,
  "timelimit": 600,       # seconds (600 = 10 minutes)
  "attempts": 1           # max attempts allowed
}
```

### Polling cron pattern (detect new quiz before class)

```bash
# Run every 3 minutes during class window; detect newly added quizzes
BEFORE_TS=$(date +%s)
QUIZZES=$(curl -s ... | jq '[.quizzes[] | select(.timeopen > NOW_TS and .timeopen < END_TS)]')
# if QUIZZES not empty and quiz ID not seen before → trigger alert / auto-attempt
```

See `references/quiz-api-flow.md` for full session notes.

### "Not currently available" error from start_attempt

Returned when the quiz `timeopen` is in the future or already past `timeclose`. Normal behavior — just wait for the window.

## SCELE Commands

```bash
~/.claude/skills/scele/bin/scele events       # All upcoming events (filtered to Kelas D)
~/.claude/skills/scele/bin/scele deadlines     # Assignment deadlines only (filtered to Kelas D)
~/.claude/skills/scele/bin/scele courses       # Enrolled courses (with course IDs)
~/.claude/skills/scele/bin/scele content MPPI              # Browse course materials
~/.claude/skills/scele/bin/scele content MPPI "Minggu 3"   # Filter to a section
~/.claude/skills/scele/bin/scele download MPPI "file.pptx"  # Download a file
~/.claude/skills/scele/bin/scele submit 206892 ~/output.pdf # Submit assignment
~/.claude/skills/scele/bin/scele status 206892              # Check submission status
~/.claude/skills/scele/bin/scele assignid 206892            # Get assignment ID from cmid
~/.claude/skills/scele/bin/scele grades MPPI               # Show grades for a course
~/.claude/skills/scele/bin/scele submissions MPPI          # All assignments + submission status
~/.claude/skills/scele/bin/scele announcements MPPI        # Recent course announcements
~/.claude/skills/scele/bin/scele assignment 204780         # Full assignment intro + naming + file limits + due
~/.claude/skills/scele/bin/scele posts 62147               # Every post in a forum discussion (verify thread batches)
~/.claude/skills/scele/bin/scele page 204768               # Body text of a page/label module
~/.claude/skills/scele/bin/scele bind out.pdf body.pdf lampiran1.pdf lampiran2.pdf   # concat PDFs
~/.claude/skills/scele/bin/scele sheet pembagian_dosen_kp $USER_NPM                  # find own row in KP dosen sheet
~/.claude/skills/scele/bin/scele me                        # print user profile constants
```

### When to reach for the new commands

- **`assignment <cmid>`** — anytime a submission slot's instructions matter (file naming format, max files, file types, deadline, cutoff). `submissions <course>` only gives the title + due date; this gives the full intro text and config constraints.
- **`posts <discussion_id>`** — when verifying that a batch of forum posts (e.g., 13 weekly logs) landed in a thread. `announcements` only shows the parent posts of recent threads, not the replies inside one.
- **`page <cmid>`** — to read the body text of any page or label module (e.g., the KP "Linimasa" or "Pengumpulan Deliverables" sections). The `content` command lists titles only.
- **`bind`** — when a SCELE slot allows only one PDF but the deliverable has lampiran (KAKP, log PDFs). Concat them in order before submitting.
- **`sheet <alias> <npm>`** — to look up the user's own row in a known Google Sheet (currently: `pembagian_dosen_kp`). Saves repeatedly fetching + grepping CSVs by hand.
- **`me`** — print the user profile constants (NPM, KP class, dosen, instansi). Useful when filling templates or filename patterns.

## Nextcloud Commands (via /nextcloud skill)

```bash
NC=~/.claude/skills/nextcloud/bin/nc
$NC list "Courses/<COURSE>"          # List course folder contents
$NC tree "Courses/<COURSE>" 3        # Tree view
$NC get "Courses/<COURSE>/file"      # Fetch file to /tmp/nc-fetch/
$NC put /local/file "Courses/<COURSE>/subdir/file"  # Upload
$NC mkdir "Courses/<COURSE>/NewDir"  # Create directory
$NC exists "Courses/<COURSE>"        # Check if folder exists
```

## Full Workflow

Follow these steps **in order** every time this skill is invoked.

### Step 0: Parse User Intent

If the user mentions specific courses (e.g., "check MPPI and KP"), focus on those courses. If they mention "today" or a specific date, highlight deadlines for that timeframe. If they ask about grades or submissions, use the appropriate commands (`grades`, `submissions`) instead of `deadlines`.

### Step 1: Fetch from SCELE

1. Run `~/.claude/skills/scele/bin/scele deadlines` (or `events` if the user asked about general events)
   - Use `submissions <course>` if the user wants to see all assignments + status for a specific course
   - Use `grades <course>` if the user asks about grades or scores
   - Use `announcements <course>` if the user asks about course news or announcements
2. If the user asked about a specific course, filter output for that course name
3. Present results naturally in the user's language (Indonesian if asked in Indonesian, English if in English)
4. Include the SCELE URL for each item so the user can click through

### Step 2: Check Telegram (ProgPar only)

**This step applies ONLY when the query involves Pemrograman Paralel / ProgPar.**

The course "Pemrograman Paralel" has a Telegram group called **"progpar 26 UI"** where assignments and materials are frequently shared. SCELE alone is not sufficient for this course.

1. Use Telegram MCP tools to find the group "progpar 26 UI" (use `search_public_chats` or `list_chats` / `get_chat`)
2. Get recent messages from the group (use `get_messages` or `list_messages`)
3. Look for assignment announcements, deadlines, or instructions
4. **Also check files/documents sent in the group** — assignment specs and templates are often shared as files (use `get_media_info` or `download_media` if needed)
5. Merge any Telegram findings with the SCELE results — if a task is on Telegram but not SCELE, include it and note "Source: ProgPar Telegram Group"

For **all other courses**, skip this step.

### Step 3: Check Nextcloud `/Courses/`

Browse the Nextcloud `Courses/` directory for additional context relevant to the deadlines found.

1. Run `$NC list "Courses"` to see which course folders exist
2. For each relevant course, run `$NC tree "Courses/<COURSE>" 3` to check for:
   - Assignment templates
   - Info documents or rubrics
   - Previous submissions for reference
3. If relevant files are found, mention them to the user (e.g., "I found a template at Courses/KP/Log/Weekly-Log-Template.docx")
4. If a course folder doesn't exist yet in Nextcloud, note it for Step 5

### Step 3.5: Cross-reference with Todoist

Before offering to add new tasks, check what's already tracked in Todoist to avoid duplicates and show the user their current academic task status.

1. Use `get_tasks` with `project_id: "6cJh8h77vj6PhWXW"` to fetch all tasks from the Main project
   - Do NOT use `filter_tasks` — the `filter` parameter is broken in the current Todoist MCP
2. Filter results for course abbreviations (KP, PPL, ProgPar, MPPI) in task titles
3. Show the user which SCELE deadlines are already tracked vs which are new
4. Highlight any Todoist tasks that are due today or overdue

### Step 4: Offer to Add Tasks to Todoist

After presenting all findings (including which are already in Todoist), offer to add only the **new/untracked** deadlines:
> "These deadlines aren't in your Todoist yet — want me to add them?"

**Rules — strictly enforced:**
- **Project**: ALWAYS use project **"Main"** (project ID: `6cJh8h77vj6PhWXW`). Never ask which project. Never use another project.
- **Priority**: ALWAYS `4` (= p1/urgent, the highest in Todoist UI). API values are inverted: 4 = p1/urgent, 3 = p2/medium, 2 = p3/low, 1 = p4/none.
- **Due datetime**: SCELE deadline **minus 12 hours**, as ISO 8601 string via `due_datetime` parameter
  - If SCELE deadline has no time, assume 23:59 as the deadline time
  - Examples:
    - SCELE "Mar 5 00:00" → `2026-03-04T12:00:00` (previous day noon)
    - SCELE "Mar 6 17:00" → `2026-03-06T05:00:00` (same day 5 AM)
    - SCELE "Mar 11 21:00" → `2026-03-11T09:00:00` (same day 9 AM)
- **Title format**: `<ABBREV> — <Task description>` (em dash U+2014)
  - Examples:
    - `KP — Weekly log`
    - `MPPI — Tugas Individu 1: Paragraph Development`
    - `ProgPar — PR presentasi 2 Maret dan 4 Maret`
    - `PPL — Submit Presentasi Laporan UAT Sprint 1`
- **Description format**:
  ```
  <Short description of the task>

  <SCELE link or reference source>
  ```
  - Example:
    ```
    Submit weekly KP log for the current week.

    https://scele.cs.ui.ac.id/mod/assign/view.php?id=12345
    ```
  - If from Telegram:
    ```
    Prepare presentation slides for ProgPar class.

    Source: ProgPar Telegram Group ("progpar 26 UI")
    ```

**Todoist MCP tool call**: Use `add_task` with these parameters:
- `content`: title string
- `description`: description string
- `priority`: `4`
- `due_datetime`: ISO 8601 string
- `project_id`: `"6cJh8h77vj6PhWXW"`

If adding multiple tasks, add them one by one and confirm each.

**Todoist MCP workarounds** (known bugs):
- `complete_task` is broken (`'TodoistAPI' object has no attribute 'close_task'`). Use `delete_task` as a workaround to clear completed tasks.
- `filter_tasks` is broken (`got an unexpected keyword argument 'filter'`). Use `get_tasks` with `project_id` instead.

### Step 5: Offer to Do the Assignment

After the Todoist step, ask the user:
> "Want me to help you work on any of these assignments?"

**Get the assignment spec first** — before helping, download and read the assignment instructions:
1. Check Nextcloud `Courses/<COURSE>/Materials/` for assignment spec files (usually `.pptx` or `.pdf`)
2. If not on Nextcloud, use `scele content <course>` to find the spec on SCELE, then `scele download` to fetch it
3. Read the spec (use `/pptx` or `/pdf` skill) to understand requirements: format, page count, rubric, naming convention, etc.

**Feasibility check** — before offering, consider:
- **Can do**: Writing assignments (essays, paragraphs, reports), filling document templates, creating presentations, data analysis, coding tasks
- **Cannot do**: Exams, group presentations that need coordination, tasks requiring physical presence
- **Missing info**: If files, rubrics, or specific instructions are needed that weren't found in SCELE/Telegram/Nextcloud, ask the user for them — don't be shy

**Available document skills**: `/docx`, `/xlsx`, `/pptx`, `/pdf` — mention these when relevant (e.g., "I can create the Word document using the /docx skill", "I can read that PDF rubric using /pdf")

**Working directory**: `~/courses/<ABBREV>/` (e.g., `~/courses/KP/`, `~/courses/MPPI/`)
- Create the directory if it doesn't exist: `mkdir -p ~/courses/<ABBREV>`
- Work on the assignment there
- When done, upload the result to Nextcloud: `$NC put ~/courses/<ABBREV>/output.docx "Courses/<COURSE>/subdir/output.docx"`
- Create new Nextcloud subdirectories if needed: `$NC mkdir "Courses/<COURSE>/NewSubdir"`

**If the user declines**: At minimum, offer to create the course folder in Nextcloud if it doesn't exist yet (e.g., "Courses/MPPI doesn't exist yet — want me to create it?")

## KP (Kerja Praktik) Workflow Primer

KP is a special course with a multi-stage deliverable chain. If the user is working on anything KP-related, this is the lay of the land so you don't have to rediscover it each time.

**The chain (in submission order):**

1. **Pendaftaran** — Google Form for KP registration (deadline ~mid Feb).
2. **Draft KAKP** — Kerangka Acuan Kerja Praktik, submitted to a SCELE assign slot (~mid Feb).
3. **Revisi KAKP** — Submit via gform that the dosen team links separately. The dosen returns a signed PDF.
4. **Final KAKP** — Upload the signed KAKP into "Ruang Unggah KAKP Tersetujui Dosen dan Mitra" on SCELE (~mid March). Filename: `<DosenCode> - <NPM> - <Nama Lengkap>.pdf`.
5. **Weekly forum logs** — Each calendar week of KP gets one reply in the "Submisi Log KP" forum (cmid varies by semester). Thread title format: `<DosenCode> - <NPM> - <Nama> - <Instansi>`. Reply title: `Log <N> (<date range>)`. The body must contain inline screenshots (JPG/PNG), not file attachments. There's a `submit_to_forum.py` helper in `~/Documents/Courses/KP/Log/` that automates this.
6. **Penyelia eval + Surat Keterangan** — The company's penyelia (not the student) emails two PDFs to `penyelia@cs.ui.ac.id` from a **company email** (e.g., `contact@aiccountant.id`). Student-side submission won't satisfy this requirement.
7. **Laporan Akhir** — One PDF, submitted to "Laporan Akhir KP - akan dinilai dan di ttd dosen". Hard constraints (verified via `scele assignment <cmid>`):
   - File type: `.pdf` only
   - Max files: 1 (so lampiran KAKP and Log PDFs must be physically bound — use `scele bind`)
   - Naming: `Final_BatchN_NPM_NamaTanpaSpasi.pdf`
   - "Batch" is effectively a placeholder for KP Reguler since the course has one deadline per semester. Defaults to `Batch1` unless the dosen tim says otherwise.

**Structure that the bound laporan PDF must follow** (from "Sistematika Penulisan Laporan KP", updated Aug 2023):

```
Halaman Judul → Halaman Persetujuan Dosen → Abstrak → Daftar Isi
→ Daftar Gambar/Tabel/Kode (rule of thumb: include only if ≥5 items)
→ BAB 1 Pendahuluan (1.1 Proses Pencarian KP, 1.2 Tempat KP)
→ BAB 2 Isi (2.1 Latar Belakang, 2.2 Deskripsi, 2.3 Tinjauan Pustaka, 2.4 Metodologi, 2.5 Teknologi, 2.6 Hasil, 2.7 Aspek Non-Teknis, 2.8 Analisis)
→ BAB 3 Penutup (3.1 Kesimpulan, 3.2 Saran)
→ Daftar Referensi
→ Lampiran 1: KAKP (bound)
→ Lampiran 2: Log KP weekly (bound)
```

Paper rules: A4, 3 cm margins all sides, page numbering required. Font/heading style is **flexible** when using the "format perusahaan / spesifik bidang" track (most students). When using full TA UI format: Times New Roman 12pt, 1.5 line spacing, plus `Universitas Indonesia` footer in Arial 10 bold right-aligned.

**Lessons baked in from past sessions:**
- Always verify submission constraints via `scele assignment <cmid>` before building the deliverable — file count limits dictate whether to bind lampiran or keep separate.
- After bulk-posting weekly logs, verify with `scele posts <discussion_id>` rather than trusting a local cache file.
- The signed KAKP PDF often has stale contact info (e.g., a personal Gmail) baked in. If the student's preferred contact has changed, use `pymupdf` redactions to replace text before re-binding the laporan. (Pure pdf-overlay is NOT enough — text remains in the stream.)

**Common laporan mistakes called out by the dosen team** (from `scele page 204768`, "READ ME: Kesalahan yang Biasa Muncul"):
- Abstrak should not begin with "laporan ini ..." — open with the actual subject (company + period + role + work + tech + result).
- Every Gambar/Tabel/Kode must be referenced in the surrounding paragraph; never drop a figure without explaining it in text.
- Each BAB (and each sub-bab) needs an intro paragraph before diving into deeper sub-sections.
- Italicize foreign words *including role titles* (`software engineer`, `full-stack`, `expense tracking`).
- Brand names: capitalize correctly, no italic. Preserve special typography (`SCeLE`, `eComindo`, `McDonald's`).
- Singkatan: expand on first use, then the abbreviation in parens — e.g., `Point of Sales (POS)`.
- Font consistency: full TA UI track requires Times New Roman 12pt; the perusahaan/spesifik-bidang track lets you pick a font but must stay consistent throughout.
- Avoid first-person. Convert active voice with "penulis ..." into passive — `Kerja praktik dilakukan ...` over `Penulis melakukan kerja praktik ...`.

## Example Interaction

User: "ada tugas apa di progpar?"

1. Run `scele deadlines`, filter for "Pemrograman Parallel"
2. **Check Telegram**: search "progpar 26 UI" group for recent assignment messages and files
3. **Check Nextcloud**: `nc list "Courses"` — note that Courses/ProgPar doesn't exist
4. Present combined results:
   > "Ada 1 deadline di ProgPar dari SCELE: PR presentasi 2 Maret dan 4 Maret, due 4 Maret jam 00:00.
   > Link: https://scele.cs.ui.ac.id/mod/assign/view.php?id=211402
   >
   > Dari Telegram group progpar 26 UI: [any additional findings]
   >
   > Note: Folder Courses/ProgPar belum ada di Nextcloud."
5. Ask: "Mau ditambahkan ke Todoist?"
6. If yes → add task: `ProgPar — PR presentasi 2 Maret dan 4 Maret`, due `2026-03-03T12:00:00`, project Main
7. Ask: "Mau aku bantu kerjain tugasnya? Bisa bikin slides presentasi pake /pptx."
8. If declined → "Mau aku buatin folder Courses/ProgPar di Nextcloud?"
