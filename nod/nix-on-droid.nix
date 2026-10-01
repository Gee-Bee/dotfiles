{ pkgs, lib, ... }:

{
  # Source of truth for the Pixel 3a: applied on the phone with
  # `nix-on-droid switch --flake /path/to/nod`.
  system.stateVersion = "24.05";

  # Static busybox login shell (root-cause #2): dropbear re-execs the shell via
  # posix_spawn fexecve too; a DYNAMIC (glibc) shell dies the same way under
  # proot. The static busybox sh (argv0 `-sh` = login ash) has no loader.
  user.shell = lib.mkForce ("${pkgs.pkgsStatic.busybox}/bin/sh");

  # Provides the termux-wake-lock binary used by startServices below; disabled
  # by default in NOD, and a missing command would abort the whole activation.
  android-integration.termux-wake-lock.enable = true;

  nix.extraOptions = "experimental-features = nix-command flakes";

  # bash provides `exec -a` for the dropbear argv0 trick (see startServices)
  environment.packages = [ pkgs.pkgsStatic.busybox pkgs.bash pkgs.tmux pkgs.vim pkgs.git ];

  # Dropbear instead of openssh: no privilege-separation user needed, so it
  # runs under proot without root. Keys mirror the NixOS host layout.
  build.activation.sshKeys = ''
    mkdir --parents "$HOME/.ssh"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPOVgbvC6NCTBNeKJG650TEcb+6bbdzs1IyrwHyYg20 greg.bunia@gmail.com" > "$HOME/.ssh/authorized_keys"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/authorized_keys"
  '';

  # HA runs from the aarch64 binary cache — no pip, no compiling cryptography.
  # User config stays in $HOME/.config/home-assistant (persistent across switches).
  build.activation.homeAssistant = ''
    if ! test -e "$HOME/.config/home-assistant"; then
      mkdir --parents "$HOME/.config/home-assistant"
      cat > "$HOME/.config/home-assistant/configuration.yaml" <<'EOF'
default_config:
frontend:
http:
  base_url: http://0.0.0.0:8123
EOF
    fi
  '';

  # Android kills background processes; wake lock holds the CPU so HA and
  # dropbear survive. Battery for the app must stay "Unrestricted".
  build.activation.startServices = ''
    # no pkill/ps/grep inside the proot bootstrap — stop old services by pidfile
    # (the file survives switches; a stale pid simply fails to signal)
    if test -f "$HOME/.config/dropbear.pid"; then kill "$(cat "$HOME/.config/dropbear.pid")" 2>/dev/null || true; fi
    # dropbear rejects shells missing from /etc/shells ("invalid shell,
    # rejected") and /etc is regenerated on every switch — re-add ours each
    # activation. Read it from /etc/passwd, NOT $SHELL (unset under
    # activation sh). ''${l##*:} keeps nix from interpolating $-params.
    while IFS= read -r l; do case $l in nix-on-droid:*) echo "''${l##*:}" >>/etc/shells;; esac; done </etc/passwd
    # pre-generate the host key in $HOME: -R generates it in the connection
    # child, which dies under proot — every connection closed before the banner
    # the activation script's PATH does NOT include the user profile, so the
    # wrapper must be found explicitly; it also FAILS (am startservice needs
    # "Display over other apps") — that must never abort the activation
    if command -v termux-wake-lock >/dev/null 2>&1; then termux-wake-lock || true
    elif test -x "$HOME/.nix-profile/bin/termux-wake-lock"; then "$HOME/.nix-profile/bin/termux-wake-lock" || true
    fi
    nohup ${pkgs.home-assistant}/bin/hass --config "$HOME/.config/home-assistant" >/dev/null 2>&1 &
    # PATH for ssh non-login sessions (busybox tools, termux wrappers)
    if test -f "$HOME/.profile"; then :; else printf '%s\n' 'PATH="$HOME/.nix-profile/bin:$PATH"' 'export PATH' > "$HOME/.profile"; fi
    # dropbear: the nixpkgs build re-execs each connection child via
    # fexecve/execveat(AT_EMPTY_PATH) — proot cannot translate that and the
    # child dies before the banner (proot -v 9 trace, exit 182). No rebuild
    # needed though: svr-main.c falls back to plain fork when open(argv[0])
    # fails, so launching with a bogus argv0 (bash `exec -a`) disables the
    # re-exec at runtime — stock binary from the cache works (verified E2E).
    test -s "$HOME/.config/dropbear_host_key" \
      || ${pkgs.dropbear}/bin/dropbearkey -t ed25519 -f "$HOME/.config/dropbear_host_key"
    # -P writes the pidfile from dropbear itself (`echo $!` only catches a
    # short-lived wrapper) — the pidfile is how the next activation stops it
    nohup ${pkgs.bash}/bin/bash -c 'exec -a /nonexistent "$0" -r "''$HOME/.config/dropbear_host_key" -P "''$HOME/.config/dropbear.pid" -p 8022' ${pkgs.dropbear}/bin/dropbear >/dev/null 2>&1 &
  '';
}
