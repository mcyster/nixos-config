#!/usr/bin/env bash

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  printf 'status line: jq not on PATH\n'
  exit 0
fi

current_directory="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
used_percentage="$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')"
total_cost_usd="$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')"
total_duration_ms="$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // 0')"

worktree_label="?"
if [[ -n "$current_directory" ]]; then
  worktree_label="${current_directory/#"$HOME"/\~}"
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
printf '%b\n' "${cyan}${worktree_label}${reset}${separator}${usage_color}ctx ${usage_label}${reset}${separator}${green}${cost_label}${reset}${separator}${dim}⏱ ${duration_label}${reset}"
