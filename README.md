# NixOS Config

Single flake repo for all machines.

## Usage

```
# build/switch for this machine
nh os switch ~/nixos-config

# pull latest nixpkgs, build and switch
nh os switch --update ~/nixos-config
```

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

## Principles

- single flake, not snowflake
- this repo is the source of truth
- any machine can be rebuilt from scratch
- no hidden state
- small bootstrap boundary (only needed for first install)
