#!/usr/bin/env bash
# Deploy nod/ flake (Nix-on-Droid) to the Pixel 3a. Run from the repo root; needs adb.
#
#   nod/deploy.sh             # copy nod/ to the phone + nix-on-droid switch (needs working ssh)
#   nod/deploy.sh --seed      # zero-state bootstrap: everything over adb, no ssh needed
#   nod/deploy.sh -s <serial> # pick a device when several are plugged in
#
# Ssh target: nix-on-droid@<ip>:8022 — the user inside the NOD proot (the
# android uid is NOT an ssh login). Overrides: NOD_IP=a.b.c.d NOD_LOGIN=...
#
# Seed flow (no ssh in the loop — phone-size eval takes 10–20 min):
#   1. push the flake + a one-line helper into the app's external dir (adb-writable)
#   2. type ONE short line into the app's shell: `sh /sdcard/.../phone-deploy.sh`
#   3. the helper copies the flake to $HOME and runs `nix-on-droid switch`
#      detached; progress + rc land in the external dir where adb reads them
#   4. verify by ssh (dropbear comes up from the freshly activated config)
set -euo pipefail

SERIAL=""
if [ $# -ge 1 ] && [ "$1" = "-s" ]; then SERIAL="$2"; shift 2; fi
# adb needs `-s <serial>` before the subcommand; plain `adb` works with one device
adbsh() { if [ -n "$SERIAL" ]; then adb -s "$SERIAL" "$@"; else adb "$@"; fi; }
die() { echo "error: $*" >&2; exit 1; }

command -v adb >/dev/null || die "adb not found (android-tools on NixOS)"
# probe via a real remote command: `adb true` is not a host-side subcommand
adbsh shell true >/dev/null 2>&1 || die "no adb device (USB debugging on + authorization accepted?)"

cd "$(dirname "$0")/.." || die "cannot cd to repo root"

LOGIN=${NOD_LOGIN:-nix-on-droid}
IP=${NOD_IP:-$(adbsh shell ip -4 addr show 2>/dev/null | tr -d '\r' \
  | sed -n 's/.*inet \([0-9.]\+\)\/.*/\1/p' | grep -v '^127\.' | head -n1)}
# usb fallback: the forward maps the phone's 8022 onto localhost (dhcp-proof)
adbsh forward tcp:8022 tcp:8022
HOST=${IP:-127.0.0.1}
echo "phone: $LOGIN@$HOST"

ssh_opts="-o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
phone() { command ssh -p 8022 $ssh_opts "$LOGIN@$HOST" "$@"; }

EXT=/sdcard/Android/data/com.termux.nix/files
if [ "${1:-}" = "--seed" ]; then
  # pm clear wipes the external dir too — recreate it (shell uid may mkdir here)
  adbsh shell mkdir -p "$EXT" 2>/dev/null || true
  adbsh shell monkey -p com.termux.nix -c android.intent.category.LAUNCHER 1 >/dev/null \
    || die "cannot launch com.termux.nix (app installed?)"
  sleep 2
  # fresh bootstrap asks "set it up with flakes? (y/N)" and, right after the
  # ~15 min initial build, "press Enter" — both are handled by ONE Enter here
  # (the initial y/N default N installs the same thing); send it and hope the
  # session is at a prompt. If the app shows the bootstrap URL dialog, tap OK
  # by hand — that one cannot be scripted reliably.
  adbsh shell input keyevent 66 || true
  echo "waiting 30 s for a settled prompt (bootstrap/initial build must be done)"
  sleep 30
  # the flake travels via adb push into the app's external dir (writable by the
  # shell uid, readable by the app — no /sdcard root permission involved)
  adbsh shell mkdir -p "$EXT/nod"
  for f in nod/flake.nix nod/flake.lock nod/nix-on-droid.nix; do
    adb push "$f" "$EXT/nod/${f#nod/}" >/dev/null || die "adb push $f failed"
  done
  adb push nod/phone-deploy.sh "$EXT/phone-deploy.sh" >/dev/null || die "adb push helper failed"
  # ONE typed line runs the helper. Plain `input text` has been seen eating
  # slashes and mangling %s, and `input keycombination` on this device inserts
  # the key as a plain character instead of a combo — so: no input text, no
  # keycombination, everything as raw lowercase keyevents (the /sdcard FUSE
  # mount is case-insensitive). Lines over ~45 chars lose a keystroke at the
  # terminal's wrap column, hence the two short lines (cd + sh) instead of one
  # absolute path. Verified by effect: the helper writes a marker as its first
  # action; missing marker -> retry (a doubled run is guarded in the helper).
  kc() { case "$1" in
    [a-z]) echo $((29 + $(printf '%d' "'$1") - 97)) ;;
    [0-9]) echo $((7 + $(printf '%d' "'$1") - 48)) ;;
    /) echo 76 ;; .) echo 56 ;; -) echo 69 ;; ' ') echo 62 ;;
    *) die "type_line: unsupported char '$1'" ;;
  esac; }
  type_line() {
    local text="$1" buf=() ch i
    for ((i=0; i<${#text}; i++)); do
      ch=${text:i:1}
      buf+=("$(kc "$ch")")
      if [ ${#buf[@]} -ge 20 ]; then
        adbsh shell input keyevent "${buf[@]}" >/dev/null; buf=(); sleep 0.2
      fi
    done
    [ ${#buf[@]} -gt 0 ] && adbsh shell input keyevent "${buf[@]}" >/dev/null
    adbsh shell input keyevent 66 >/dev/null                 # Enter
  }
  flush_sweep() {
    adbsh shell input keyevent 66 >/dev/null                 # drop any half-line
    adbsh shell input keyevent 66 >/dev/null
    sleep 0.5
  }
  line1="cd /sdcard/android/data/com.termux.nix/files"
  line2="sh phone-deploy.sh"
  # kc failures inside $( ) cannot abort the script — validate the lines up front
  for ln in "$line1" "$line2"; do
    for ((i=0; i<${#ln}; i++)); do ch=${ln:i:1}; kc "$ch" >/dev/null; done
  done
  marker_ok() {
    adbsh shell "test -f '$EXT/deploy-started' && echo yes" 2>/dev/null | grep -q yes
  }
  rm_marker() {
    adbsh shell "rm -f '$EXT/deploy-started'"
  }
  # keystrokes land in whatever window holds input focus — wake the screen,
  # dismiss the keyguard and refuse to type unless the app is focused
  adbsh shell input keyevent KEYCODE_WAKEUP
  adbsh shell input keyevent 82
  sleep 1
  foc=$(adbsh shell dumpsys window 2>/dev/null | grep mCurrentFocus || true)
  case "$foc" in
    *com.termux.nix*) ;;
    *) die "Termux window not focused (${foc#*=}) — unlock the phone, focus the app" ;;
  esac
  rm_marker
  flush_sweep
  type_line "$line1"
  sleep 1                                                 # let the cd land first
  type_line "$line2"
  echo "helper launched — verifying by effect (marker file)…"
  ok=0
  for _ in $(seq 1 12); do
    if marker_ok; then ok=1; break; fi
    sleep 5
  done
  if [ "$ok" != 1 ]; then
    echo "marker missing — flushing the line and retrying…"
    rm_marker
    flush_sweep
    type_line "$line1"
    sleep 1
    type_line "$line2"
    for _ in $(seq 1 12); do
      if marker_ok; then ok=1; break; fi
      sleep 5
    done
  fi
  [ "$ok" = 1 ] || die "typed line never landed (marker '$EXT/deploy-started' absent) — open the app and run:
    cd /sdcard/Android/data/com.termux.nix/files
    sh phone-deploy.sh"
  echo "marker ok — switch running on the phone (eval takes 10–20 min)…"
  echo "watch live: adb shell tail -f \"$EXT/switch-out.log\""
  rc=""
  seen_alive=0
  dead=0
  start=$SECONDS
  # 360 × 20 s = 2 h: a from-scratch run downloads the whole closure over wifi
  for _ in $(seq 1 360); do
    last=$(adbsh shell "tail -n 1 '$EXT/deploy-progress.txt' 2>/dev/null" | tr -d '\r' || true)
    case "$last" in
      *"switch rc="*) rc=${last##*rc=}; break ;;
    esac
    # eval is silent for minutes — liveness comes from ps (guest argv needs -o
    # ARGS); gone only after a sighting, so adb hiccups cannot abort a live run
    logline=$(adbsh shell "tail -n 1 '$EXT/switch-out.log' 2>/dev/null" | tr -d '\r')
    psout=$(adbsh shell "ps -A -o ARGS 2>/dev/null" | tr -d '\r')
    state=starting
    case $psout in
      "") state='adb?' ;;
      *nix/store*) seen_alive=1; dead=0; state=alive ;;
      *)
        if [ "$seen_alive" = 1 ]; then
          dead=$((dead + 1))
          if [ "$dead" -ge 2 ]; then state=GONE; fi
        else
          dead=0
        fi
        ;;
    esac
    elapsed=$((SECONDS - start))
    printf '\r\033[K  %02d:%02d  switch %-8s  |  %s' \
      $((elapsed / 60)) $((elapsed % 60)) "$state" "${logline:0:70}"
    if [ "$state" = GONE ]; then
      echo
      adbsh shell "tail -n 5 '$EXT/switch-out.log' 2>/dev/null" | sed 's/^/  | /' || true
      die "switch process disappeared without rc — see $EXT/switch-out.log"
    fi
    sleep 20
  done
  echo
  [ "$rc" = "0" ] || {
    adbsh shell "tail -n 5 '$EXT/switch-out.log' 2>/dev/null" | sed 's/^/  | /' || true
    die "switch on the phone failed (rc=${rc:-timeout}) — full log: $EXT/switch-out.log"
  }
  # a fresh install generates a new host key and accept-new does not override
  # a stale known_hosts entry — drop the old one or verify fails misleadingly
  ssh-keygen -R "[${HOST}]:8022" >/dev/null 2>&1 || true
  echo "switch finished (rc=0) — verifying ssh…"
  for _ in $(seq 1 6); do
    if phone true 2>/dev/null; then break; fi
    sleep 10
  done
  phone 'echo SSH_LOGIN_OK; id; rm -rf ~/.config/nix-on-droid' 2>/dev/null \
    || die "switch ok but ssh does not answer (dropbear not up?)"
  echo "deployed.${IP:+ HA: http://$IP:8123}"
  exit 0
fi

# --- normal path: ssh works, refresh the flake copy and switch again --------
phone 'mkdir -p src/dotfiles/nod'
for f in nod/flake.nix nod/flake.lock nod/nix-on-droid.nix; do
  phone "cat > src/dotfiles/nod/${f#nod/}" < "$f"
done

# The switch's activation restarts dropbear, which kills the ssh session
# carrying the switch itself — so run it detached under nohup with a
# completion marker and poll instead of one foreground ssh.
phone "rm -f ~/switch.rc; nohup sh -c 'nix-on-droid switch --flake ~/src/dotfiles/nod; echo \$? > ~/switch.rc' >~/switch.log 2>&1 &"
for _ in $(seq 1 120); do
  phone 'test -e ~/switch.rc' 2>/dev/null && break
  sleep 10
done
rc=$(phone 'cat ~/switch.rc 2>/dev/null' 2>/dev/null || echo 9)
phone 'tail -3 ~/switch.log 2>/dev/null' 2>/dev/null || true
[ "$rc" = "0" ] || die "nix-on-droid switch failed (rc=$rc) — see ~/switch.log on the phone"
echo "deployed.${IP:+ HA: http://$IP:8123}"
