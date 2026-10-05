# Pixel 3a — Nix-on-Droid

The phone runs Home Assistant + ssh (dropbear), managed declaratively from this directory (`flake.nix` + `nix-on-droid.nix`); everything comes from the nixpkgs binary cache. Design decisions and the hard-won workarounds are commented in `deploy.sh` and `nix-on-droid.nix` — read those, not this file.

## First install

1. Install **Nix-on-Droid** from F-Droid (`com.termux.nix`); tap OK on the bootstrap dialog and let the initial build finish (10–20 min, a growing counter is normal).
2. App info → Battery: **Unrestricted** (otherwise Android kills the services).
3. Unlock the phone, plug it in (USB debugging on), then from the repo root: `nod/deploy.sh --seed`

The script pushes the flake over adb, types the launcher line into the app's shell and the switch runs detached on the phone; deploy.sh watches it live and finishes with an ssh check.

## Deploying changes

```bash
nod/deploy.sh        # override: NOD_IP=a.b.c.d nod/deploy.sh
```

After a phone reboot open the app once — services come up from activation.

## Cheat sheet

- ssh as `nix-on-droid` on port 8022 (the android uid is not a login); on the t530: `adb forward tcp:8022 tcp:8022`, then `ssh nod`.
- Config lives on the phone at `~/src/dotfiles/nod`; rollback: `nix-on-droid rollback`; free space: `nix-on-droid-collect-garbage`.
- Progress/failure logs: `$EXT/deploy-progress.txt` and `$EXT/switch-out.log` (`$EXT` = `/sdcard/Android/data/com.termux.nix/files`, readable over adb).
- Later: TooGoodToGo as an HA integration (HACS, `~/.config/home-assistant/custom_components/`).
