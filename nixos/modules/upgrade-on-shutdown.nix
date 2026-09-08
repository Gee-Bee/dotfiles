{ config, pkgs, ... }:

let
  upgradeScript = pkgs.writeScript "upgrade-on-shutdown-fish" ''
    #!${pkgs.fish}/bin/fish

    # Skip if the running system generation is less than 7 days old.
    if test -e /run/current-system; and test /run/current-system -nt (date -d "7 days ago" +%s)
      echo ">>> System updated within the last 7 days. Skipping."
      exit 0
    end

    echo ">>> More than a week since the last update. Resolving repository..."

    # Dynamically locate the live disk path of your configuration from the system registry.
    set LIVE_REPO (${pkgs.nix}/bin/nix flake metadata flake:self --json | ${pkgs.jq}/bin/jq -r '.path')

    if not test -d "$LIVE_REPO"
      echo ">>> Error: Could not resolve valid live repository path. Aborting."
      exit 1
    end

    cd "$LIVE_REPO"
    echo ">>> Updating flake.lock with auto-commit..."

    # Update lockfile, commit changes to Git, and generate boot entries for tomorrow.
    if ${pkgs.nix}/bin/nix flake update --commit-lock-file
      nixos-rebuild boot --flake .
      echo ">>> Upgrade completed successfully and committed to Git. See you tomorrow!"
    else
      echo ">>> Error: Network unreachable or flake update failed. Aborting."
      exit 1
    end
  '';
in
{
  systemd.services.upgrade-on-shutdown = {
    description = "NixOS Flake Upgrade on Shutdown (Weekly Pure with Git Commit)";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    before = [ "shutdown.target" "reboot.target" "poweroff.target" ];
    wantedBy = [ "shutdown.target" "reboot.target" "poweroff.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${upgradeScript}";
      TimeoutStopSec = "30min";
      StandardOutput = "tty";
      StandardError = "tty";
    };
  };
}
