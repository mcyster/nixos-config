# AGENTS.md

Instructions for AI agents working in this repository.

## Updating / rebuilding a machine

Always pull before rebuilding. Use `nh`, not raw `nixos-rebuild`.

All hosts: pull first, then rebuild.

### fox

```sh
git -C ~/nixos-config pull
nh os switch --update ~/nixos-config
```

### moa (Extole work machine)

`moa` requires private files under `.private/` that are git-ignored, so you
**must** use `path:` instead of a git URL.

```sh
cd ~/nixos-config
git pull
nh os switch --update path:.
```

If the Extole checkout (`~/extole`) or VPN config changed, run the sync script
first:

```sh
./scripts/sync-moa-work-config
nh os switch --update path:.
```

**Do not** use `nh os switch ~/nixos-config` or `--flake <git-url>#moa` on
moa — the `.private/` directory will be invisible to the flake evaluator and
the build will fail with a missing-file assertion.

### roo (remote VPS)

Edit on fox, push, then apply remotely:

```sh
ssh wal@173.255.249.111
nh os switch --refresh github:mcyster/nixos-config#roo
```

Note: `--refresh` fetches the latest from GitHub, so no separate pull is needed
on roo.

## Key rules

- `nh` is the preferred CLI; avoid raw `nixos-rebuild`.
- Always `git pull` before rebuilding (or use `--update`).
- `--update` updates flake inputs (i.e. pulls the latest `nixos-unstable`);
  omitting it rebuilds the pinned `flake.lock` version. When the user says
  "update the system", use `--update`.
- On moa, always use `path:` — never a GitHub flake ref.
- On roo, `--refresh` handles the pull.

## X session warning

If `$DISPLAY` or `$WAYLAND_DISPLAY` is set, the user is in a graphical session.
Running `nh os switch` from within X/Wayland may restart the display manager
and kill the current session. Warn the user and suggest running from a TTY
(e.g. Ctrl+Alt+F3) instead, or confirm they accept the restart.
