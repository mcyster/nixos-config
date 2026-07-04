{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.nh = {
    enable = true;
    flake = "/home/wal/nixos-config";
  };

  environment.systemPackages = with pkgs; [
    git
    nh
    vim
    # Restored from old modules/my.nix
    direnv
    opencode
    cursor-cli
    ripgrep
    btop
    jq
    wget
    zip
    unzip
    usbutils
    pciutils
    lshw
    lsof
    acpi
    dmidecode
  ];
}
