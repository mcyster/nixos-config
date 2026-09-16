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

    # direnv's per-directory approval is keyed on the .envrc path, so every new
    # git worktree needs another `direnv allow`. Trust our own home directories
    # instead: any .envrc under them loads without prompting.
    settings.whitelist.prefix = [
      "/home/mcyster"
      "/home/wal"
    ];
  };
}
