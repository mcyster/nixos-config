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
}
