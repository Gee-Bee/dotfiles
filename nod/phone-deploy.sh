#!/bin/sh
# On-phone deploy helper (pushed by deploy.sh --seed, run with ONE typed line).
# Copies the pushed flake into $HOME and starts `nix-on-droid switch` detached.
# Progress lands in the app's external dir, where adb can read it — the whole
# bootstrap loop needs no ssh; ssh is only the final verification.
EXT=/sdcard/Android/data/com.termux.nix/files
# exported: the detached sh below expands $EXT (plain vars die with this shell)
export EXT
# first thing: proof of life — deploy.sh polls this marker to know the typed
# line actually landed (input-text mangling is verified by effect, not by echo)
echo started > "$EXT/deploy-started"

# double-run guard: a retried typed line must not queue a second switch
if [ -e ~/nod-deploy.running ]; then exit 0; fi
touch ~/nod-deploy.running

mkdir -p ~/src/dotfiles/nod
cp "$EXT"/nod/* ~/src/dotfiles/nod/

# fresh marker, then switch detached: activation restarts dropbear / kills the
# foreground job, so the switch must not run inside a typed session either.
# Absolute binary + explicit experimental-features: non-login sh has neither
# the profile PATH (rc=127) nor flake features enabled.
rm -f ~/switch.rc "$EXT"/deploy-progress.txt
echo "$(date +%T) starting switch" >> "$EXT"/deploy-progress.txt
# rc lands twice: ~/switch.rc for the ssh path and the progress file for the
# adb poll — app-private files are invisible to adb, the progress file is not
nohup sh -c 'NIX_CONFIG="experimental-features = nix-command flakes" $HOME/.nix-profile/bin/nix-on-droid switch --flake ~/src/dotfiles/nod#default > "$EXT/switch-out.log" 2>&1; rc=$?; echo "$rc" > ~/switch.rc; echo "$(date +%T) switch rc=$rc" >> "$EXT/deploy-progress.txt"; rm -f ~/nod-deploy.running' >/dev/null 2>&1 &
echo "$(date +%T) switch detached (bg $!)" >> "$EXT"/deploy-progress.txt
