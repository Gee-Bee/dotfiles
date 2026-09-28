#!/usr/bin/env bash
# Deploy nod/ flake (Nix-on-Droid) to the Pixel 3a. Run from the laptop; needs adb.
#
#   nod/deploy.sh             # rsync nod/ + nix-on-droid switch over ssh
#   nod/deploy.sh --seed      # zero-state bootstrap: types the seed into the
#                             # phone over adb (unlock the screen, that's all),
#                             # then deploys as soon as dropbear answers
#   nod/deploy.sh -s <serial> # pick a device when several are plugged in
#
# uid/ip are discovered over adb: the app uid owns /data/data/com.termux.nix,
# the ip comes from `ip addr`. Overrides:
# NOD_UID=u0_aNNN NOD_IP=a.b.c.d nod/deploy.sh
set -euo pipefail

SERIAL=""
[ $# -ge 1 ] && [ "$1" = "-s" ] && { SERIAL="$2"; shift 2; }

# adb joins its shell argv with spaces into one command string, so plain
# unquoted fragments are the reliable way to pass commands.
adbsh() { if [ -n "$SERIAL" ]; then adb -s "$SERIAL" shell "$@"; else adb shell "$@"; fi; }
die() { echo "error: $*" >&2; exit 1; }

command -v adb >/dev/null || die "adb not found (android-tools on NixOS)"
# probe via a real remote command: get-state exists only host-side, toybox on
# the phone lacks it and would exit 127 even on a healthy device
adbsh true >/dev/null 2>&1 || die "no adb device (USB debugging on + authorization accepted?)"

detect_uid() {
  # primary: owner of the app's private dir; fallback: package dumpsys
  local u
  u=$(adbsh stat -c %U /data/data/com.termux.nix/files/home 2>/dev/null | tr -d '\r')
  if [ -z "$u" ]; then
    u=$(adbsh dumpsys package com.termux.nix 2>/dev/null | tr -d '\r' \
      | sed -n 's/.*userId=\([0-9]\+\).*/\1/p' | head -n1)
    [ -n "$u" ] && u="u0_a$((u - 10000))"
  fi
  echo "$u"
}

detect_ip() {
  # first global IPv4 (wlan0 or whatever is up), loopback excluded;
  # ifconfig fallback for the few builds without iproute2
  local out
  out=$(adbsh ip -4 addr show 2>/dev/null | tr -d '\r' \
    | sed -n 's/.*inet \([0-9.]\+\)\/[0-9]\+.*/\1/p' | grep -v '^127\.' | head -n1)
  if [ -z "$out" ]; then
    out=$(adbsh ifconfig 2>/dev/null | tr -d '\r' \
      | sed -n 's/ *inet addr:\([0-9.]\+\).*/\1/p' | grep -v '^127\.' | head -n1)
  fi
  echo "$out"
}

UID_OUT=${NOD_UID:-$(detect_uid)}
[ -n "$UID_OUT" ] || die "cannot read phone uid (app missing? set NOD_UID=u0_aNNN)"
IP=${NOD_IP:-$(detect_ip)}
[ -n "$IP" ] || die "cannot read phone ip (wifi off? set NOD_IP=a.b.c.d)"
echo "phone: $UID_OUT@$IP"

ssh_opts="-p 8022 -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

if [ "${1:-}" = "--seed" ]; then
  seed=1
  # Seed = the full `echo <b64>|base64 -d|sh` typed into the app's shell over
  # adb — bare base64 would just be an unknown bash command. Single quotes per
  # chunk carry spaces and pipes through adb's shell layer; `input text`
  # truncates long strings on some builds, hence 512-char chunks with one
  # Enter at the end.
  b64=$(base64 -w0 nod/bootstrap-seed.sh 2>/dev/null || base64 nod/bootstrap-seed.sh | tr -d '\n')
  type_seed() {
    adbsh monkey -p com.termux.nix -c android.intent.category.LAUNCHER 1 >/dev/null \
      || die "cannot launch com.termux.nix (app installed?)"
    sleep 2
    # `n` answers the first-run wizard's flake question ("no"); without the
    # wizard it is just a harmless "command not found"
    adbsh input text n
    adbsh input keyevent 66
    # mapfile, not `while read`: fold's last chunk has no trailing newline and
    # `while read` would silently drop it (a truncated `echo <b64>` just prints
    # and never pipes to base64)
    mapfile -t parts < <(printf 'echo %s|base64 -d|sh' "$b64" | fold -w 512)
    for part in "${parts[@]}"; do
      adbsh "input text '$part'"
    done
    adbsh input keyevent 66
  }
  # keyevent 224 wakes a merely-off screen; behind a lock screen the one unlock
  # is the only human step
  echo "== wake/unlock the phone screen now — seeding is typed over adb, the rest runs unattended =="
  # first-ever app launch downloads the NOD bootstrap before any shell exists,
  # so retype every minute until dropbear answers (the payload is idempotent)
  up=0
  for _ in $(seq 1 12); do
    type_seed
    for _ in $(seq 1 6); do
      if ssh $ssh_opts "$UID_OUT@$IP" true 2>/dev/null; then up=1; break; fi
      sleep 10
    done
    [ "$up" = 1 ] && break
    echo "no dropbear yet — retyping seed (is the screen unlocked?)"
  done
  [ "$up" = 1 ] || die "dropbear still not up — paste this line into the app's shell manually, then rerun nod/deploy.sh

echo $b64|base64 -d|sh"
fi

rsync -avz --delete --exclude '.git' -e "ssh -p 8022" \
  "$PWD/nod/" "$UID_OUT@$IP:src/dotfiles/nod/"
ssh -p 8022 "$UID_OUT@$IP" 'nix-on-droid switch --flake ~/src/dotfiles/nod'
# Seed config is superseded by the flake now; drop it so a bare
# `nix-on-droid switch` on the phone can never silently re-seed.
[ -z "${seed:-}" ] || ssh -p 8022 "$UID_OUT@$IP" 'rm -f ~/.config/nixpkgs/nix-on-droid.nix'
echo "deployed. HA: http://$IP:8123"
