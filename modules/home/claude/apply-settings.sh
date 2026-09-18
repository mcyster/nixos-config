#!/usr/bin/env bash
# Merge the declarative Claude Code baseline into ~/.claude/settings.json.
#
# settings.json cannot be a nix store symlink: Claude Code writes to it at
# runtime (dialog acknowledgements, /permissions additions). So instead of
# owning the file, we own the keys we care about and merge them in on every
# home-manager activation, leaving everything else Claude Code wrote intact.
#
# Run standalone to apply without a rebuild, no arguments needed:
#   modules/home/claude/apply-settings.sh
#
# Both arguments are optional and default to the baseline sitting next to this
# script and the real settings file. home-manager passes both explicitly,
# because in the nix store the two files land at unrelated paths.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
baseline="${1:-$here/settings-baseline.json}"
target="${2:-$HOME/.claude/settings.json}"

[ -f "$baseline" ] || {
  echo "apply-settings.sh: no baseline at $baseline" >&2
  exit 1
}

mkdir -p "$(dirname "$target")"
[ -f "$target" ] || echo '{}' >"$target"

tmp="$(mktemp "${target}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

# `. * $b` deep-merges with the baseline winning; arrays are replaced wholesale,
# which is what we want for deny/additionalDirectories. allow is the exception:
# union it so "don't ask again" entries Claude Code appended survive a rebuild.
jq --slurpfile base "$baseline" '
  ($base[0]) as $b
  | (.permissions.allow // []) as $existing
  | ($b.permissions.allow // []) as $required
  | . * $b
  | .permissions.allow = ($required + ($existing - $required))
' "$target" >"$tmp"

mv "$tmp" "$target"
