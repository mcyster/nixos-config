{ pkgs, lib, ... }:
{
  # home-manager owns ~/.claude/statusline.sh, so it lands as a read-only
  # symlink into the nix store. Edit modules/home/claude/statusline.sh and
  # rebuild instead of editing the file in $HOME (or using /statusline).
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;
  };

  # ~/.claude/settings.json stays a real writable file (Claude Code writes to
  # it), so home-manager can't own it outright. Instead settings-baseline.json
  # holds the keys we want to survive a rebuild -- notably the permission
  # posture -- and apply-settings.sh merges them in on each activation.
  #
  # Permission posture lives there, not in the UI: defaultMode is
  # "bypassPermissions" so no action ever waits on a prompt. The deny list is
  # the counterweight and is applied authoritatively -- edits to it in $HOME are
  # reverted on the next switch.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="${lib.makeBinPath [ pkgs.jq pkgs.coreutils ]}:$PATH" \
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${./apply-settings.sh} \
        ${./settings-baseline.json} "$HOME/.claude/settings.json"
  '';
}
