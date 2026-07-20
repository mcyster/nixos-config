{ config, pkgs, ... }:

{
  # IMPORTANT: adjust these per machine before/after install
  networking.hostName = "bootstrap";
  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.wal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    nh
    curl
  ];

  services.openssh.enable = true;

  assertions = [
    {
      assertion = config.networking.hostName != "bootstrap";
      message = "bootstrap hostname must be changed to match a real host";
    }
  ];
}
