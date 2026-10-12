{ lib, pkgs, ... }:
let
  screenshotDbusAuditPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.dbus-next
  ]);
  screenshotDbusAudit = pkgs.writeTextFile {
    name = "screenshot-dbus-audit";
    executable = true;
    destination = "/bin/screenshot-dbus-audit";
    text = ''
      #!${screenshotDbusAuditPython}/bin/python3
      import asyncio
      import json
      import os

      from dbus_next import Message, MessageType
      from dbus_next.aio import MessageBus


      SCREENSHOT_INTERFACES = {
          "org.gnome.Shell.Screenshot",
          "org.freedesktop.portal.Screenshot",
      }
      MATCH_RULES = [
          "type='method_call',interface='org.gnome.Shell.Screenshot'",
          "type='method_call',interface='org.freedesktop.portal.Screenshot'",
          (
              "type='signal',sender='org.freedesktop.DBus',"
              "interface='org.freedesktop.DBus',member='NameOwnerChanged'"
          ),
      ]


      def executable(pid):
          try:
              return os.readlink(f"/proc/{pid}/exe")
          except OSError:
              return None


      def process_identity(pid):
          try:
              stat = open(f"/proc/{pid}/stat", encoding="utf-8").read()
              ppid = int(stat.rpartition(") ")[2].split()[1])
          except (IndexError, OSError, ValueError):
              ppid = None

          return {
              "pid": pid,
              "executable": executable(pid),
              "parent_pid": ppid,
              "parent_executable": executable(ppid) if ppid is not None else None,
          }


      async def main():
          resolver = await MessageBus().connect()
          monitor = await MessageBus().connect()
          identities = {}
          resolutions = {}
          loop = asyncio.get_running_loop()

          async def resolve_sender(sender):
              reply = await resolver.call(
                  Message(
                      destination="org.freedesktop.DBus",
                      path="/org/freedesktop/DBus",
                      interface="org.freedesktop.DBus",
                      member="GetConnectionUnixProcessID",
                      signature="s",
                      body=[sender],
                  )
              )
              identity = None
              if reply.message_type == MessageType.METHOD_RETURN:
                  identity = process_identity(reply.body[0])
              identities[sender] = identity
              return identity

          def resolution_for(sender):
              task = resolutions.get(sender)
              if task is None:
                  task = loop.create_task(resolve_sender(sender))
                  resolutions[sender] = task
              return task

          def forget(sender):
              identities.pop(sender, None)
              resolutions.pop(sender, None)

          async def log_screenshot_call(message):
              identity = identities.get(message.sender)
              if identity is None:
                  try:
                      identity = await resolution_for(message.sender)
                  except Exception:
                      identity = None

              event = {
                  "event": "screenshot-dbus-call",
                  "interface": message.interface,
                  "member": message.member,
                  "sender": message.sender,
              }
              if identity is not None:
                  event.update(identity)
              print(json.dumps(event, sort_keys=True), flush=True)

          def handle_message(message):
              if (
                  message.message_type == MessageType.SIGNAL
                  and message.interface == "org.freedesktop.DBus"
                  and message.member == "NameOwnerChanged"
              ):
                  name, old_owner, new_owner = message.body
                  if name.startswith(":") and not old_owner and new_owner:
                      resolution_for(name)
                  elif name.startswith(":") and old_owner and not new_owner:
                      loop.call_later(30, forget, name)
              elif (
                  message.message_type == MessageType.METHOD_CALL
                  and message.interface in SCREENSHOT_INTERFACES
              ):
                  loop.create_task(log_screenshot_call(message))

          monitor.add_message_handler(handle_message)
          reply = await monitor.call(
              Message(
                  destination="org.freedesktop.DBus",
                  path="/org/freedesktop/DBus",
                  interface="org.freedesktop.DBus.Monitoring",
                  member="BecomeMonitor",
                  signature="asu",
                  body=[MATCH_RULES, 0],
              )
          )
          if reply.message_type == MessageType.ERROR:
              raise RuntimeError(reply.error_name)

          print(
              json.dumps({"event": "screenshot-dbus-audit-started"}),
              flush=True,
          )
          await asyncio.Future()


      asyncio.run(main())
    '';
  };
in
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
      change_directory_by_prefix "''${PROJECT_HOME:-$HOME/extole/master}" "''${1:-}"
    }

    cdc() {
      local project_name="''${1:-}"
      local project_code_directory="''${PROJECT_CODE:-$HOME/extole/master/code}"

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

  systemd.user.services.screenshot-dbus-audit = {
    Unit = {
      Description = "Audit GNOME screenshot D-Bus calls";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe screenshotDbusAudit;
      Restart = "always";
      RestartSec = 2;
      SyslogIdentifier = "screenshot-dbus-audit";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."opencode/opencode.jsonc".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "permission": "allow"
    }
  '';
}
