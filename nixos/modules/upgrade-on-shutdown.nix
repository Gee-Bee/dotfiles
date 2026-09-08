{ config, pkgs, ... }:

let
  upgradeScript = pkgs.writeScript "upgrade-on-shutdown-fish" ''
    #!${pkgs.fish}/bin/fish

    function log
      echo ">>> $argv"
    end

    # /run/current-system's own mtime updates on every switch, so this is
    # true whenever the running generation is younger than 7 days.
    if test -n (${pkgs.findutils}/bin/find /run/current-system -mtime -7)
      log "System updated within the last 7 days. Skipping."
      exit 0
    end

    log "More than a week since the last update. Resolving repository..."
    set -l repo (${pkgs.nix}/bin/nix flake metadata flake:self --json | ${pkgs.jq}/bin/jq -r '.path')

    if not test -d "$repo"
      log "Error: could not resolve live repository path. Aborting."
      exit 1
    end

    cd "$repo"
    log "Updating flake.lock with auto-commit..."

    if not ${pkgs.nix}/bin/nix flake update --commit-lock-file
      log "Error: network unreachable or flake update failed. Aborting."
      exit 1
    end

    ${config.system.build.nixos-rebuild}/bin/nixos-rebuild boot --flake .
    log "Upgrade completed and committed to Git. See you tomorrow!"
  '';
in
{
  systemd.services.upgrade-on-shutdown = {
    description = "NixOS Flake Upgrade on Shutdown (Weekly Pure with Git Commit)";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    before = [ "shutdown.target" "reboot.target" "poweroff.target" ];
    conflicts = [ "shutdown.target" "reboot.target" "poweroff.target" ];
    wantedBy = [ "multi-user.target" ]; # must be ACTIVE during normal runtime for ExecStop to fire on shutdown

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${upgradeScript}";
      TimeoutStopSec = "30min";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };
}
