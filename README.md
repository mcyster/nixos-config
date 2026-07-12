# NixOS Config

Single flake repo for all machines.

## Principles

- single flake, not snowflake
- this repo is the source of truth
- any machine can be rebuilt from scratch
- no hidden state
- small bootstrap boundary (only needed for first install)

## Usage

```
# build/switch for this machine
# uses $HOSTNAME, which must exist as a host in the flake
nh os switch ~/nixos-config

# update inputs (pull latest versions) and switch
nh os switch --update
```

## Work machine (`moa`)

`moa` uses Extole's module from the private `~/extole` checkout. Its
personalized VPN modules are generated under `.private/moa` and are deliberately
excluded from this public repository.

```bash
# Refresh after updating ~/extole or the VPN configuration in /etc/nixos
./scripts/sync-moa-work-config

# path: is required so Nix includes the Git-ignored .private directory
nh os build "path:$PWD"
nh os switch "path:$PWD"
```

The WireGuard private keys remain outside the Nix store at:

```text
/etc/wireguard/vpn-dev.key
/etc/wireguard/vpn-prod.key
```

Keep both files owned by `root:root` with mode `0600`, and restore them from an
Extole-approved password manager or secret store when rebuilding the machine.
Do not put a private key directly in a Nix expression: Nix store files are
readable by every local user. Because this repository is public, encrypted
corporate secrets should also stay out of it unless Extole policy explicitly
permits that storage.

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
