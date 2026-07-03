# NixOS Config

Single flake repo for all machines.

## Structure

```
hosts/<host>/configuration.nix   # machine-specific
modules/base.nix                 # baseline (currently my.nix)
modules/desktop.nix              # GUI
modules/games.nix                # gaming
modules/dev.nix                  # dev tools
```

## Usage

```
# build/switch for this machine
# uses $HOSTNAME, which must exist as a host in the flake
nh os switch ~/nixos-config

# update inputs (pull latest versions) and switch
nh os switch --update
```

## Notes

- `/etc/nixos` is only used during initial install
- real config lives in this repo
- add/remove modules per host via `imports`
- `system.stateVersion` must be set per machine (do not blindly use the bootstrap value)
- hostname must match a host entry in the flake (or use `#host` explicitly)

## Bootstrap (fresh machine)

From the ISO:

```
nixos-generate-config --root /mnt

curl -L https://raw.githubusercontent.com/mcyster/nixos-config/main/bootstrap/configuration.nix \
  -o /mnt/etc/nixos/configuration.nix

nixos-install
reboot
```

Then after login:

```
nix run github:nix-community/nh -- os switch github:mcyster/nixos-config#$(hostname)
```

Important:
- After first boot, update `system.stateVersion` in your host config to match the system's original install version
- Ensure `networking.hostName` matches your intended flake host (or use `#host` when switching)
