{ ... }:
{
  home.stateVersion = "25.11";

  home.sessionVariables.OWNER = "mark2";

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
