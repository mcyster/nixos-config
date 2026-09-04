#!/usr/bin/env bash

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  printf 'status line: jq not on PATH\n'
  exit 0
fi

current_directory="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
used_percentage="$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')"
total_cost_usd="$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')"
total_duration_ms="$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // 0')"

# The session's own directory never moves: the Bash tool resets its cwd to the project
# directory after every call, so .workspace.current_dir stays pinned to the clone Claude
# was started in even while the whole session works inside a worktree elsewhere. The
# transcript is the only record of where the work actually lands, so the working tree is
# recovered from the paths the session names, newest first.
#
# The nesting matters here. An Extole ticket workspace is a tech worktree at
# $E_WORKSPACE/<branch> holding each participating repository as its own worktree at
# code/<repo> -- independent git repositories that happen to sit inside another one, not
# submodules, and invisible to the outer repository because code/ is gitignored. So no
# path convention is assumed and nothing is asked of the outer repository: each candidate
# path is handed to `git -C` on its own, and git reports the innermost working tree
# containing it, whichever repository that turns out to belong to.
active_directory=""
active_branch=""

# Where a command runs, and what it writes, say the session is working there. What it
# merely reads does not -- otherwise every `cat` of a file in an unrelated repository
# would move the status line. The first alternative takes an edited file's path, which the
# extraction below puts on a line of its own.
working_path_pattern='^/\S+$'
working_path_pattern+='|(?<![\w./-])cd\s+\K[^\s;&|)'"'"'"]+'
working_path_pattern+='|(?<![\w./-])git\s+-C\s+\K[^\s;&|)'"'"'"]+'
working_path_pattern+='|>>?\s*\K/[^\s;&|<>)'"'"'"]+'
working_path_pattern+='|(?<![\w./-])tee\s+(?:-\S+\s+)*\K/[^\s;&|<>)'"'"'"]+'

# One jq and one grep over the tail of the transcript, in transcript order. Reaching for a
# process per entry instead is what turns this from milliseconds into most of a second on
# a long session, and the status line is redrawn constantly.
collect_candidate_paths() {
  [[ -n "$transcript_path" && -f "$transcript_path" ]] || return 0

  local match
  while IFS= read -r match; do
    [[ -n "$match" ]] && candidate_paths+=("$match")
  done < <(tail -c 2000000 "$transcript_path" 2>/dev/null | tail -n +2 | tail -n 400 \
    | jq -r 'try (.message.content[]?
        | select(.type == "tool_use")
        | if (.name == "Edit" or .name == "Write" or .name == "NotebookEdit")
          then (.input.file_path // empty)
          elif .name == "Bash"
          then ((.input.command // "") | gsub("[\n\r]"; " "))
          else empty
          end) catch empty' 2>/dev/null \
    | grep -oP "$working_path_pattern" 2>/dev/null)
}

resolve_active_working_tree() {
  local candidate_paths=()
  collect_candidate_paths
  (( ${#candidate_paths[@]} > 0 )) || return 0

  # Newest first, and cached per directory: a single command can name a dozen paths, and
  # asking git about each one separately is what the status line's whole runtime would go
  # on. The cap is a floor on responsiveness, not a coverage target -- if sixty paths back
  # names no working tree, the session is not working in one.
  local -A top_level_by_directory=()
  local scanned=0 index candidate directory top_level
  for (( index = ${#candidate_paths[@]} - 1; index >= 0; index-- )); do
    (( scanned++ < 60 )) || break

    candidate="${candidate_paths[index]}"
    # A path is only usable literally. Anything carrying shell syntax -- a variable, a
    # glob, a substitution -- would have to be run to know what it named, and a stray
    # fragment of one must not survive to have its parent directory taken below, because
    # that parent is the project directory and the status line would never leave it.
    [[ "$candidate" =~ ^[A-Za-z0-9._~@+/-]+$ ]] || continue
    [[ "$candidate" == /* ]] || candidate="$current_directory/$candidate"

    if [[ -d "$candidate" ]]; then
      directory="$candidate"
    elif [[ -f "$candidate" || "$candidate" == */?* ]]; then
      # A redirect names a file that need not exist yet, so its directory is what places
      # it. Only a candidate that actually spells a directory earns that fallback.
      directory="${candidate%/*}"
      [[ -d "$directory" ]] || continue
    else
      continue
    fi

    if [[ -v top_level_by_directory[$directory] ]]; then
      top_level="${top_level_by_directory[$directory]}"
    else
      top_level="$(git -C "$directory" rev-parse --show-toplevel 2>/dev/null)"
      top_level_by_directory[$directory]="$top_level"
    fi
    [[ -n "$top_level" ]] || continue

    # The newest resolvable path wins, whichever tree it names. Stopping at the first hit
    # is what lets the status line come back to the base checkout as soon as the session
    # returns to it, instead of staying on a worktree it left an hour ago.
    active_directory="$top_level"
    active_branch="$(git -C "$top_level" branch --show-current 2>/dev/null)"
    return 0
  done
}
resolve_declared_working_tree() {
  local session_id record recorded=""

  [[ -n "$transcript_path" ]] || return 0
  session_id="$(basename "$transcript_path")"
  session_id="${session_id%.jsonl}"
  [[ -n "$session_id" ]] || return 0

  record="${XDG_CACHE_HOME:-$HOME/.cache}/extole/workspace-by-session/$session_id"
  [[ -f "$record" ]] || return 0
  read -r recorded < "$record" || return 0
  [[ -n "$recorded" && -d "$recorded" ]] || return 0

  active_directory="$recorded"
  active_branch="$(git -C "$recorded" branch --show-current 2>/dev/null)"
}
resolve_declared_working_tree

[[ -n "$active_directory" ]] || resolve_active_working_tree

[[ -n "$active_directory" ]] || active_directory="$current_directory"
location_label="?"
if [[ -n "$active_directory" ]]; then
  location_label="${active_directory/#"$HOME"/\~}"
fi

# A ticket workspace is named for its branch and its tech worktree is deliberately
# detached, so the branch is usually either already in the path or absent. Show it only
# when it adds something the path does not already say.
branch_label=""
if [[ -n "$active_branch" && "/$location_label/" != *"/$active_branch/"* ]]; then
  branch_label="$active_branch"
fi

humanize_duration() {
  local milliseconds="${1%.*}"
  [[ "$milliseconds" =~ ^[0-9]+$ ]] || milliseconds=0
  local total_seconds=$(( milliseconds / 1000 ))
  local hours=$(( total_seconds / 3600 ))
  local minutes=$(( (total_seconds % 3600) / 60 ))
  local seconds=$(( total_seconds % 60 ))
  if (( hours > 0 )); then
    printf '%dh%02dm' "$hours" "$minutes"
  elif (( minutes > 0 )); then
    printf '%dm%02ds' "$minutes" "$seconds"
  else
    printf '%ds' "$seconds"
  fi
}
duration_label="$(humanize_duration "$total_duration_ms")"

cost_label="$(printf '$%.2f' "$total_cost_usd" 2>/dev/null || printf '$%s' "$total_cost_usd")"

reset=$'\033[0m'
dim=$'\033[2m'
cyan=$'\033[36m'
magenta=$'\033[35m'
green=$'\033[32m'
yellow=$'\033[33m'
red=$'\033[31m'

usage_label="n/a"
usage_color="$dim"
if [[ "$used_percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  used_percentage_integer="${used_percentage%.*}"
  usage_label="${used_percentage_integer}%"
  if (( used_percentage_integer >= 80 )); then
    usage_color="$red"
  elif (( used_percentage_integer >= 50 )); then
    usage_color="$yellow"
  else
    usage_color="$green"
  fi
fi

separator=" ${dim}·${reset} "
line="${cyan}${location_label}${reset}"
[[ -n "$branch_label" ]] && line+=" ${magenta}⎇ ${branch_label}${reset}"
line+="${separator}${usage_color}ctx ${usage_label}${reset}${separator}${green}${cost_label}${reset}${separator}${dim}⏱ ${duration_label}${reset}"
printf '%b\n' "$line"
