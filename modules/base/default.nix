{ ... }:
{
  imports = [
    ./users.nix
    ./nix.nix
  ];

  programs.ssh.extraConfig = ''
    Host roo
      HostName 173.255.249.111
      User wal
  '';

  programs.ssh.startAgent = true;

  # Disable GNOME's SSH agent to avoid conflict with programs.ssh.startAgent
  services.gnome.gcr-ssh-agent.enable = false;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
