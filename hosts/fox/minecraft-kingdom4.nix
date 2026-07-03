{ config, pkgs, lib, ... }:

let
  paperJar = "/home/minecraft/kingdom4/paper/paper-1.21.10.jar";
  serverMemory = { minimum = "2G"; maximum = "4G"; };
in
{
  users.groups.minecraft = {};

  users.users.minecraft = {
    isNormalUser = lib.mkForce true;
    isSystemUser = lib.mkForce false;
    home = lib.mkForce "/home/minecraft";
    createHome = lib.mkForce true;
    group = lib.mkForce "minecraft";
  };

  systemd.tmpfiles.rules = [
    "d /home/minecraft 0750 minecraft minecraft -"
    "d /home/minecraft/kingdom4 0750 minecraft minecraft -"
    "d /home/minecraft/kingdom4/paper 0750 minecraft minecraft -"
  ];

  environment.systemPackages = with pkgs; [
    minecraft-server
  ];

  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    openFirewall = true;

    dataDir = "/home/minecraft/kingdom4";

    package = pkgs.minecraft-server;

    serverProperties = {
      "server-port" = 25565;
      "motd" = "Kingdom4";
      "online-mode" = false;
      "level-name" = "world1";
      "view-distance" = 10;
      "enable-command-block" = true;
      "difficulty" = "normal";
    };
  };

  systemd.services.minecraft-server.serviceConfig = {
    WorkingDirectory = lib.mkForce "/home/minecraft/kingdom4";
    ReadWritePaths = lib.mkForce [ "/home/minecraft/kingdom4" ];
    ProtectHome = lib.mkForce false;
    DynamicUser = lib.mkForce false;

    ExecStart = lib.mkForce [
      ""
      "${pkgs.jre_headless}/bin/java -Xms${serverMemory.minimum} -Xmx${serverMemory.maximum} -jar ${paperJar} nogui"
    ];
  };

  networking.firewall.allowedUDPPorts = [ 24454 ];

  systemd.timers.minecraft-server-start = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 18:00:00";
      Persistent = true;
    };
  };

  systemd.services.minecraft-server-start = {
    script = ''
      ${pkgs.systemd}/bin/systemctl start minecraft-server.service
    '';
  };

  systemd.timers.minecraft-server-stop = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 21:30:00";
      Persistent = true;
    };
  };

  systemd.services.minecraft-server-stop = {
    script = ''
      ${pkgs.systemd}/bin/systemctl stop minecraft-server.service
    '';
  };
}
