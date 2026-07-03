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
# build/switch for this machine (hostname must match)
nh os switch ~/nixos-config

# explicit host
nh os switch ~/nixos-config#fox

# update inputs
nh os switch --update
```

## Notes

- `/etc/nixos` is only used during initial install
- real config lives in this repo
- add/remove modules per host via `imports`

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

If hostname doesn’t match, replace `$(hostname)` with the correct one (e.g. `fox`).
