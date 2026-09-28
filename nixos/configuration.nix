{ ... }:

let
  primaryUser = "gb";
in
{
  _module.args.primaryUser = primaryUser;

  imports = [
    ./t530-generated-hardware-configuration.nix
    ./modules/boot.nix
    ./modules/desktop-kde.nix
    ./modules/networking.nix
    ./modules/audio-bluetooth.nix
    ./modules/users.nix
    ./modules/programs.nix
    ./modules/ai.nix
    ./modules/nix-on-droid.nix
    ./modules/services/upgrade-on-shutdown.nix
    ./modules/services/thumbnails-pregeneration.nix
    ./modules/desktop/plasmoids/on-air
  ];

  # Stateful-data defaults from the initial install release; bump only after reading the release notes.
  system.stateVersion = "24.05";

  time.timeZone = "Europe/Warsaw";
}
