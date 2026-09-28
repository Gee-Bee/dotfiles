{ pkgs, ... }:

{
  # Source of truth for the Pixel 3a: applied on the phone with
  # `nix-on-droid switch --flake /path/to/nod`. The app ships its own nix
  # with flakes enabled, so no package installation on the phone is involved.
  system.stateVersion = "24.05";

  # Provides the termux-wake-lock binary used by startServices below; disabled
  # by default in NOD, and a missing command would abort the whole activation.
  android-integration.termux-wake-lock.enable = true;

  nix.extraOptions = "experimental-features = nix-command flakes";

  environment.packages = with pkgs; [
    tmux
    vim
    git
    dropbear
  ];

  # Dropbear instead of openssh: no privilege-separation user needed, so it runs
  # under proot without root. Keys mirror the NixOS host layout.
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

  # Android keeps killing background processes; wake lock holds the CPU so HA
  # and dropbear survive. Battery for the app must stay "Unrestricted".
  build.activation.startServices = ''
    # pkill returns 1 when nothing matched (always true on first run) and the
    # activation script runs under set -eu — guard or the switch aborts.
    pkill -f 'home-assistant' 2>/dev/null || true
    termux-wake-lock
    nohup ${pkgs.home-assistant}/bin/hass --config "$HOME/.config/home-assistant" >/dev/null 2>&1 &
    nohup ${pkgs.dropbear}/bin/dropbear -R -p 8022 >/dev/null 2>&1 &
  '';
}
