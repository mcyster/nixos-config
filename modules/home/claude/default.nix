{ ... }:
{
  # home-manager owns ~/.claude/statusline.sh, so it lands as a read-only
  # symlink into the nix store. Edit modules/home/claude/statusline.sh and
  # rebuild instead of editing the file in $HOME (or using /statusline).
  #
  # ~/.claude/settings.json stays unmanaged (Claude Code writes to it); it
  # refers to this script as:
  #   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;
  };
}
