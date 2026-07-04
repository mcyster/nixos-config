# roo

`roo` is the Linode VPS running NixOS from this flake.

Linode Cloud Manager:

```text
https://cloud.linode.com/linodes/39574149
```

## Access

SSH as `wal` using the normal local key:

```sh
ssh wal@173.255.249.111
```

`wal` is an admin user via `wheel` and has passwordless sudo. Root SSH is intentionally not configured.

## Workflow

Normal config changes are made from `fox`, then applied on `roo`.

On `fox`:

```sh
cd ~/nixos-config
git pull
vim hosts/roo/configuration.nix
git add .
git commit -m "roo: describe change"
git push
```

On `roo`:

```sh
ssh wal@173.255.249.111
nh os switch --refresh github:mcyster/nixos-config#roo
```

For recovery-sensitive changes, use an exact commit on `roo`:

```sh
nh os switch github:mcyster/nixos-config/<commit>#roo
```

## Bootstrap

Use Linode rescue/Finnix only for the initial install or recovery. The normal system should boot via the Linode `Direct Disk` profile.

Bootstrap gotchas from the first install:

- Do not leave the Linode profile on `GRUB 2`; it dropped to a raw `grub>` prompt for this host. Use `Direct Disk` so the GRUB installed on `/dev/sda` is used.
- Finnix has a small live filesystem. Do not install Nix into the Finnix root; use the mounted target disk for `/nix`.
- Nix will not accept `/nix` as a symlink. Use a real directory or bind mount, for example mount the target root at `/mnt` and bind `/mnt/nix` to `/nix`.
- If running Nix from Finnix, create the `nixbld` group/users first or builds can fail with `the group 'nixbld' specified in 'build-users-group' does not exist`.
- For recovery-sensitive deploys, use an exact commit like `github:mcyster/nixos-config/<commit>#roo`; otherwise GitHub flake caching can reuse an older commit.
- Before removing any temporary root access, confirm `wal` can SSH and run `sudo -n true`.
- SSH host keys change between Finnix and NixOS, and after reinstall. Use a separate `UserKnownHostsFile` during rescue or remove stale keys with `ssh-keygen -R 173.255.249.111`.

## Linode Settings

- Label: `roo`
- Boot profile kernel: `Direct Disk`
- `/dev/sda`: main NixOS disk, still may have an old Linode disk label
- `/dev/sdb`: swap image
- Maintenance Policy: `Migrate`
- Interfaces: keep `Configuration Profile` interfaces unless there is a specific need to upgrade
