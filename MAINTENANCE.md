# Arch maintenance: updating, cleaning, rolling back

Reference for keeping an Arch install healthy — the equivalents of `apt upgrade`,
`apt autoremove` and `apt autoclean`, and what actually breaks Arch systems.

Measurements marked *(snapshot)* were taken **2026-08-05 on host `sohrab`**
(Dell laptop, ext4 root, Intel i915). Re-measure before acting on them.

---

## 1. Updating

### There is no safer command than `pacman -Syu`

`pacman -Syu` **is** the safe command. Arch supports only fully-synced systems,
so the "smaller", more cautious-looking update is the dangerous one. Upgrades
break for the reasons below, not because `-Syu` is too blunt.

```bash
checkupdates; yay -Qua        # preview both halves, changes nothing   (alias: upcheck)
sudo pacman -Syu              # repos first
yay -Sua                      # then AUR only (-Sua, not -Syu: don't redo the repo half)
sudo pacdiff                  # merge any .pacnew files the upgrade left behind
```

The middle two steps are the `upgrade` alias in `~/.zshrc`; `upcheck` is the
preview. Both come from `home/dot_zshrc`.

`checkupdates` (pacman-contrib) compares against a *throwaway* copy of the sync
db, so unlike `pacman -Sy` it cannot leave the system half-upgraded. It exits `2`
when there is nothing to do — chain it with `;`, not `&&`.

### What actually breaks upgrades

**A full disk.** Pacman downloads *and* extracts before committing the
transaction; running out of space part-way leaves partially written files. Check
before a big upgrade:
```bash
df -h /
```
*(snapshot: 95% full, 3.8 GiB free, with 29 GiB of that being caches — see §2.)*

**Partial upgrades.** `pacman -Sy foo`, or `-Sy` now and installing later, pulls
in a package built against libraries you don't have yet. This is the classic Arch
breaker. Only ever `-Syu`. Never `--overwrite`, `-Rdd` or `--force` to push
through an error.

**Unmerged `.pacnew` files.** Package upgrades that can't safely replace a config
you edited drop a `.pacnew` beside it. Ignored long enough, the config drift
shows up as breakage weeks later, disconnected from any upgrade.
```bash
find /etc -name '*.pacnew'                    # what's pending
sudo DIFFPROG="nvim -d" pacdiff               # walk and merge them
```
*(snapshot: `/etc/locale.gen.pacnew`, `/etc/pacman.d/mirrorlist.pacnew`,
`/etc/makepkg.conf.d/fortran.conf.pacnew` pending.)*

**Stale AUR builds.** When a repo upgrade bumps a library soname (qt5, electron,
ffmpeg…), AUR packages linked against the old one stay broken until rebuilt.
Doing repos and AUR as two steps makes it obvious which half failed.

**Kernel upgrade without a reboot.** Module loading fails until you reboot
(USB devices, filesystems, DKMS drivers). Reboot after any `linux*` upgrade.
Installing **`linux-lts`** as a second kernel gives you a working boot entry when
a new kernel regresses — the cheapest insurance on Arch.
*(snapshot: only `linux` was installed, no fallback kernel. `linux-lts` is now
declared in `shared/pacman.txt`, so the next `./install.sh` adds it and
systemd-boot gets a second entry; pick it from the boot menu when a `linux`
upgrade breaks something.)*

**Long gaps between updates.** `archlinux-keyring` expires and every signature
starts failing. If that happens: `sudo pacman -Sy archlinux-keyring` first, then
the full `-Syu`. Update monthly rather than yearly.

**Arch news.** Manual-intervention notices are announced, not automated.
`informant` (AUR) is a pacman hook that blocks upgrades until unread news is
acknowledged. Caveat: it also blocks `--noconfirm` runs, so it conflicts with
unattended `install.sh` runs.

### Rolling back

There are no filesystem snapshots on ext4, so the practical rollback path is the
package cache — which is the reason not to empty it (§2):

```bash
ls /var/cache/pacman/pkg | grep '^<pkg>-'                        # available versions
sudo pacman -U /var/cache/pacman/pkg/<pkg>-<oldver>.pkg.tar.zst  # reinstall an older one
```
The `downgrade` AUR helper automates the same thing (including from the Arch
Linux Archive).

Real snapshot-and-rollback, NixOS-style, needs **btrfs + `snapper` + `snap-pac`**
(pacman pre/post-transaction hooks that snapshot every transaction). That means
converting or reinstalling the root filesystem. On ext4, `timeshift` in rsync
mode, run manually before upgrades, is the substitute.

---

## 2. Cleaning up

### `apt autoremove` → orphan removal

Pacman deliberately does not auto-remove. Orphans are packages installed as a
dependency that nothing currently requires:

```bash
pacman -Qdt                       # list them (with descriptions)
sudo pacman -Rns $(pacman -Qdtq)  # remove; re-run, since removal creates new orphans
yay -Yc                           # same, including AUR packages
```

> **Check the list before removing.** `-Qdt` also catches packages you genuinely
> want that happen to have been pulled in as a dependency rather than installed
> explicitly. Reclassify keepers instead of losing them:
> ```bash
> sudo pacman -D --asexplicit vlc go just mpv
> ```
> *(snapshot: 57 orphans, including `vlc` — which is declared in
> `shared/pacman.txt` — plus `go`, `just`, `mpv`, `kitty-terminfo`,
> `kitty-shell-integration`, `ttf-jetbrains-mono`.)*

Cross-check orphans against this repo's declared packages before removing
anything — anything in both lists should be marked `--asexplicit`, not deleted.
That check (and its two mirror images) is now a script:

```bash
cd ~/dotfiles && ./bin/pkg-diff.sh
```

Its third section, *"Declared but installed as a dependency"*, is exactly this
trap: those packages are declared by this repo, so they must not be removed, but
pacman will keep listing them under `-Qdt` until they are reclassified. Run it
**before** any orphan cleanup. The other two sections catch drift in the other
direction — declared-but-missing (usually an AUR build that failed silently
during `install.sh`) and installed-but-undeclared (a fresh machine would not get
it).

**`-debug` orphans.** `/etc/makepkg.conf` ships `debug` in `OPTIONS`, so every
AUR build also produces and installs a `<pkg>-debug` package.
*(snapshot: 14 of the 57 orphans.)* To stop it, a drop-in
`/etc/makepkg.conf.d/zz-*.conf` containing:
```bash
OPTIONS+=(!debug)
```
This works because makepkg sources `/etc/makepkg.conf.d/*.conf` *after*
`/etc/makepkg.conf`, and its `in_opt_array` scans the array **backwards**, so the
last matching entry wins (verified in `/usr/share/makepkg/util/option.sh`).

### `apt autoclean` → `paccache`

| Command | Effect | Freed *(snapshot)* |
| --- | --- | --- |
| `sudo paccache -rk3` | keep the 3 newest versions of each package | **9.77 GiB** |
| `sudo paccache -ruk0` | drop everything belonging to uninstalled packages | **974 MiB** |
| `yay -Sc` | clear yay's build/source tree (`~/.cache/yay`) | **12 GiB** |
| `sudo pacman -Sc` | keep only currently-installed versions | more — **kills rollback** |
| `sudo pacman -Scc` | delete the entire cache | emergencies only |

Always dry-run first (`-d` is an operation, so it replaces `-r`, not adds to it):
```bash
paccache -dk3         # dry run: keep 3
paccache -duk0        # dry run: uninstalled packages
du -sh /var/cache/pacman/pkg ~/.cache/yay
```

Automate the weekly equivalent of `autoclean` — ships with pacman-contrib, runs
`paccache -r`:
```bash
sudo systemctl enable --now paccache.timer
```

**No old kernels to clean.** Unlike Ubuntu, pacman replaces the kernel in place;
nothing accumulates.

### Recommended cleanup, in order

```bash
paccache -dk3 && paccache -duk0        # 1. see what would go
sudo paccache -rk3 && sudo paccache -ruk0
yay -Sc                                # 2. build cache
pacman -Qdt                            # 3. review orphans, --asexplicit the keepers
sudo pacman -Rns $(pacman -Qdtq)       #    then remove the rest
sudo pacdiff                           # 4. merge pending .pacnew files
sudo systemctl enable --now paccache.timer   # 5. keep it from coming back
```
*(snapshot: ~23 GiB reclaimable, taking the root filesystem from 95% to ~65%.)*

---

## Handy queries

```bash
pacman -Qe                  # explicitly installed (what you actually asked for)
pacman -Qdt                 # orphans
pacman -Qm                  # foreign/AUR packages
pactree -r <pkg>            # what depends on <pkg>  (why can't I remove it?)
pacman -Qi <pkg>            # install reason, size, dependencies
expac -H M '%m\t%n' | sort -h | tail -30   # 30 biggest installed packages (expac)
pacman -Qtdq | wc -l        # orphan count, for a status bar
```
