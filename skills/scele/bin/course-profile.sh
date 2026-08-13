#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

course_profile_path() {
  printf '%s\n' "${1:-${SCELE_COURSE_PROFILE:-$SCRIPT_DIR/../course-profile.json}}"
}

validate_course_profile() {
  local profile
  profile="$(course_profile_path "${1:-}")"

  [[ -r "$profile" ]] || { echo "course profile: unreadable profile: $profile" >&2; return 1; }
  jq -e '.' "$profile" >/dev/null 2>&1 || { echo "course profile: invalid JSON: $profile" >&2; return 1; }
  jq -e 'type == "object" and (.term | type == "object") and (.courses | type == "array" and length > 0)' "$profile" >/dev/null || { echo "course profile: expected term and non-empty courses" >&2; return 1; }
  jq -e '(.term.name | type == "string" and test("\\S")) and (.term.timezone | type == "string" and test("\\S"))' "$profile" >/dev/null || { echo "course profile: term fields must be non-whitespace strings" >&2; return 1; }
  jq -e 'all(.courses[]; type == "object" and (.alias | type == "string" and test("\\S")) and (.scele_course_id | type == "number" and . > 0 and floor == .) and (.scele_shortname | type == "string" and test("\\S")) and (.display_name | type == "string" and test("\\S")) and (.todoist_prefix | type == "string" and test("\\S")) and (.telegram_group == null or (.telegram_group | type == "string" and test("\\S"))) and (.lab_team == null or (.lab_team | type == "string" and test("\\S"))) and (.lecturers | type == "array" and all(.[]; type == "string" and test("\\S"))) and ((has("todoist_aliases") | not) or (.todoist_aliases | type == "array")))' "$profile" >/dev/null || { echo "course profile: invalid course metadata" >&2; return 1; }
  jq -e 'all(.courses[]; (.todoist_aliases // []) | all(.[]; type == "object" and (.scele_cmid | type == "number" and . > 0 and floor == .) and (.task_title | type == "string" and test("\\S"))))' "$profile" >/dev/null || { echo "course profile: invalid todoist_aliases" >&2; return 1; }
  jq -e '([.courses[].alias | ascii_downcase] | unique | length) == (.courses | length) and ([.courses[].scele_course_id] | unique | length) == (.courses | length) and ([.courses[].scele_shortname] | unique | length) == (.courses | length) and ([.courses[].todoist_prefix] | unique | length) == (.courses | length) and all(.courses[]; (.todoist_aliases // []) as $aliases | ([$aliases[].scele_cmid] | unique | length) == ($aliases | length))' "$profile" >/dev/null || { echo "course profile: duplicate course identity or Todoist alias" >&2; return 1; }
}

profile_course_ids() {
  local profile
  validate_course_profile "${1:-}" || return 1
  profile="$(course_profile_path "${1:-}")"
  jq -er '.courses[].scele_course_id' "$profile"
}

profile_aliases() {
  local profile
  validate_course_profile "${1:-}" || return 1
  profile="$(course_profile_path "${1:-}")"
  jq -er '.courses[].alias' "$profile"
}

profile_course_id() {
  local alias="$1" profile course_id
  profile="$(course_profile_path "${2:-}")"
  validate_course_profile "$profile" || return 1
  if ! course_id="$(jq -er --arg alias "$alias" '.courses[] | select((.alias | ascii_downcase) == ($alias | ascii_downcase)) | .scele_course_id' "$profile")"; then
    echo "course profile: unknown alias: $alias" >&2
    return 1
  fi
  printf '%s\n' "$course_id"
}
