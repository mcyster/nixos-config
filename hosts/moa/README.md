# moa

`moa` is the Extole work machine running NixOS, managed from this flake.

## Extole Integration

`moa` uses Extole's module from the private `~/extole` checkout. Its
personalized VPN modules are generated under `.private/moa` and are deliberately
excluded from this public repository.

## Secrets

The WireGuard private keys remain outside the Nix store at:

```text
/etc/wireguard/vpn-dev.key
/etc/wireguard/vpn-prod.key
```

Keep both files owned by `root:root` with mode `0600`. They are restored from
the encrypted secrets repository by `scripts/sync-moa-work-config`, or directly
with `~/secrets/scripts/wireguard-sync /etc/wireguard`.
Do not put a private key directly in a Nix expression: Nix store files are
readable by every local user. Because this repository is public, encrypted
corporate secrets should also stay out of it unless Extole policy explicitly
permits that storage.

## Workflow

On `moa`:

```sh
cd ~/nixos-config

# Refresh after updating ~/extole or the VPN configuration in /etc/nnn
./scripts/sync-moa-work-config

# Build and switch
nh os switch path:.

# Or pull latest nixpkgs and switch
nh os switch --update path:.
```

`path:` is required so Nix includes the Git-ignored `.private` directory.

For recovery-sensitive changes, use an exact commit:

```sh
nh os switch github:mcyster/nixos-config/<commit>#moa
```
