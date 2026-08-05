# System-level config (`/etc`) and services

Everything in here is applied by `install.sh` with `sudo`. This is the root-owned
counterpart to `home/` (which chezmoi owns): chezmoi only manages files in
`$HOME`, so `/etc` files live here as plain files instead of heredocs inside the
installer.

```
system/
  etc/…                       files copied to /etc on EVERY host
  services.txt                systemd units enabled on EVERY host
  hosts/<hostname>/etc/…      per-host /etc files (optional)
  hosts/<hostname>/services.txt   per-host units, appended to the shared list (optional)
```

`<hostname>` matches `hostnamectl --static`. Per-host files are applied *after*
the shared ones, so a per-host file at the same path wins.

## How files are copied

The `etc/` directory mirrors the real filesystem: `system/etc/greetd/config.toml`
→ `/etc/greetd/config.toml`. For each file, `install.sh`:

1. renders it (see templates below),
2. compares it with what is already on disk — identical means skip, so re-runs
   are quiet,
3. if it differs and a file is already there, copies that file once to
   `<path>.dotfiles-bak` (never overwriting an existing `.dotfiles-bak`),
4. installs it `root:root`, mode `0644`, creating parent directories.

Nothing is ever deleted: removing a file from this directory does **not** remove
it from `/etc`. Do that by hand.

## Templates (`.in`)

A file whose name ends in `.in` is a template. The suffix is dropped and these
placeholders are substituted:

| Placeholder | Value |
| --- | --- |
| `@USER_NAME@` | the user running `install.sh` (`$SUDO_USER`, else `$USER`) |
| `@HOSTNAME@` | `hostnamectl --static` |

Example: `system/etc/ssh/sshd_config.d/10-dotfiles.conf.in` →
`/etc/ssh/sshd_config.d/10-dotfiles.conf` with `AllowUsers ali`.

## Adding something

- **A new `/etc` file**: create it at the mirrored path under `system/etc/`
  (or `system/hosts/<hostname>/etc/`) and re-run `./install.sh`.
- **A new service**: add the unit name to `services.txt` (or the per-host file).
- **A file needing a non-0644 mode** (a key, a sudoers drop-in): don't put it
  here — `install.sh` hard-codes `0644`. Handle it explicitly in the script.

## Current contents

| File | Purpose |
| --- | --- |
| `etc/greetd/config.toml` | greetd → tuigreet → `start-hyprland` |
| `etc/bluetooth/main.conf` | experimental + fast-connect + auto-enable |
| `etc/ssh/sshd_config.d/10-dotfiles.conf.in` | no password auth, no root login, single allowed user |
