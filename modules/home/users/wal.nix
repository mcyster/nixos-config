{ ... }:
{
  home.stateVersion = "25.11";

  xdg.configFile."opencode/opencode.jsonc".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "permission": "allow"
    }
  '';
}
