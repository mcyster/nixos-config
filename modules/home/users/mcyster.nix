{ lib, ... }:
{
  imports = [ ../claude ];

  home.stateVersion = "25.11";

  programs.bash.initExtra = lib.mkAfter ''
    e_eclipse() {
      (
        if [[ -z "''${E_HOME:-}" ]]; then
          echo "E_HOME not defined"
          exit 1
        fi
        cd -- "$E_HOME/code/pluribus" || exit
        eclipse -data "$HOME/.eclipse/extole" --Xms2048m -Xmx4096m
      )
    }
    alias e-eclipse=e_eclipse

    unalias cd- 2>/dev/null
    unalias cdc 2>/dev/null

    change_directory_by_prefix() {
      local base_directory="''${1:-}"
      local requested_name="''${2:-}"
      local requested_basename="''${requested_name##*/}"
      local matched_paths=()
      local matched_path=""

      if [[ -z "$requested_basename" ]]; then
        builtin cd -- "$base_directory"
        return
      fi

      shopt -s nullglob
      matched_paths=("$base_directory"/"$requested_basename"*)
      shopt -u nullglob

      for matched_path in "''${matched_paths[@]}"; do
        if [[ -d "$matched_path" ]]; then
          builtin cd -- "$matched_path"
          return
        fi
      done

      builtin cd -- "$base_directory"
    }

    cd-() {
      change_directory_by_prefix "''${PROJECT_HOME:-$HOME/extole}" "''${1:-}"
    }

    cdc() {
      local project_name="''${1:-}"
      local project_code_directory="''${PROJECT_CODE:-$HOME/extole/code}"

      change_directory_by_prefix "$project_code_directory" "$project_name"
    }
  '';

  # home-manager owns this list, so new shortcuts belong here rather than in
  # Settings -> Keyboard: anything added there is reverted on the next switch.
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Terminal";
      command = "gnome-console --new-window";
      binding = "<Control><Alt>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Toggle Audio Device";
      command = "audio-toggle";
      binding = "<Super>q";
    };
  };

  xdg.configFile."opencode/opencode.jsonc".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "permission": "allow"
    }
  '';
}
