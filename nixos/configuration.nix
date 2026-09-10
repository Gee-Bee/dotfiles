{ config, pkgs, lib, ... }:

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
    ./modules/services/upgrade-on-shutdown.nix
    ./modules/services/thumbnails-pregeneration.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org).
  system.stateVersion = "24.05"; # Did you read the comment?

  time.timeZone = "Europe/Warsaw";
}
