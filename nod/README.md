# Pixel 3a — Nix-on-Droid

The phone (Google Pixel 3a, aarch64) is managed declaratively with [Nix-on-Droid](https://github.com/nix-community/nix-on-droid). Configuration: this directory (`flake.nix` + `nix-on-droid.nix`). Home Assistant and dropbear come from the nixpkgs binary cache — no compilation on the phone.

## One-off install (manual)

1. Install **Nix-on-Droid** from F-Droid (`com.termux.nix`); first launch downloads the bootstrap — tap OK on the "Bootstrap zipball location" dialog, then let the initial build finish (10–20 min on one core, it keeps evaluating: a progress line with a growing download counter is normal). If a dialog ever asks about backup, "Backup Allowed" stays false — that is fine.
2. Android → Apps → Nix-on-Droid → Battery: **Unrestricted** (otherwise Android kills the services).
3. Unlock the phone, plug it in (USB debugging on), then from the repo root:

```bash
nod/deploy.sh --seed
```

The script pushes the seed payload over adb into the app's external dir (`/sdcard/Android/data/com.termux.nix/files/`) and types **two short lines** into the app's shell: `cd /sdcard/android/data/com.termux.nix/files` + `sh phone-deploy.sh`. The app dir is the only choice: at the /sdcard root adb-created files get `root:everybody` FUSE pinning and the app cannot read them (chmod is ignored by FUSE).

Typing rules (all hard-won against silent mangling, see deploy.sh `type_line`):

- plain `input text` has been seen eating slashes and mangling `%s` — everything goes out as raw `input keyevent` batches instead,
- `input keycombination` inserts the key as a plain character on this device (a shift-combo produced `ash` from `sh`) — capitals must be avoided, not shifted; the `/sdcard` FUSE mount is case-insensitive, so paths are typed all-lowercase,
- lines over ~45 characters lose a keystroke at the terminal's wrap column — hence `cd` (44 chars) + bare `sh phone-deploy.sh` instead of one absolute path,
- before typing: wake the screen and require `mCurrentFocus` to name `com.termux.nix` (keys land in whatever window holds focus),
- delivery is verified by effect, not echo: the helper writes `$EXT/deploy-started` as its first action, missing marker → retry. The payload is idempotent (double-run guard inside).

The helper copies the flake into the app home and runs the first `nix-on-droid switch` detached (10–20 min on one core); deploy.sh polls the progress file over adb and finishes with an ssh check.

## Deploying changes

```bash
nod/deploy.sh        # override: NOD_IP=a.b.c.d nod/deploy.sh
```

Ssh logs in as `nix-on-droid` (the user inside the NOD proot — the android uid is **not** an ssh login) on port 8022. Ip comes from adb (`ip addr`); without wifi the script falls back to `adb forward tcp:8022 tcp:8022` → `127.0.0.1` (dhcp-proof, usb). Files are copied per-file with `ssh 'cat > file'` — the phone needs no rsync.

The switch runs **detached** (`nohup` + `~/switch.rc` marker): its activation restarts dropbear, which would otherwise kill the ssh session carrying the switch itself.

On the t530, `nixos/modules/nix-on-droid.nix` defines a device-agnostic `nod` ssh alias (`ssh nod` after `adb forward tcp:8022 tcp:8022`); the login user goes on the alias's `User` line — uid-hostile on purpose, since `nix-on-droid` survives reinstalls while `u0_aNNN` does not.

## What runs on the phone

`build.activation.startServices` on every `nix-on-droid switch`:

- HA, config in `~/.config/home-assistant` (persistent), UI: `http://<phone-ip>:8123`,
- stock dropbear from the nixpkgs cache on 8022, started with a bogus argv0 (`bash -c 'exec -a /nonexistent …'`): the 2022.83 build re-execs every connection child via fexecve/execveat, which proot cannot translate — the child dies before the ssh banner (exit 182); svr-main.c falls back to plain fork when `open(argv[0])` fails, so the stock binary needs no rebuild. Host key lives in `$HOME/.config/dropbear_host_key` (/etc is regenerated every switch),
- the login shell is re-added to `/etc/shells` every activation — dropbear rejects shells missing from that list (`invalid shell, rejected`), and NOD ships no file with the nix-store bash in it; the shell itself is the static busybox sh (a dynamic shell dies the same fexecve way).

After a full phone reboot: open the Nix-on-Droid app once — services come up from activation.

## Config changes

Edit `nix-on-droid.nix` → `nod/deploy.sh` (or `nix-on-droid switch --flake ~/src/dotfiles/nod` on the phone). Rollback: `nix-on-droid rollback`; generations live on the phone, `nix-on-droid-collect-garbage` frees space.

## Later

TooGoodToGo: HA integration instead of standalone scripts — HACS with custom_components in `~/.config/home-assistant/custom_components/` (persistent in home).
