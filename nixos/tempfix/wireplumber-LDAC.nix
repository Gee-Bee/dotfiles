# TEMPFIX(wireplumber-LDAC): delete this module and its import in configuration.nix when
# https://github.com/NixOS/nixpkgs/issues/511056 closes (or at 26.11). wireplumber 0.5.14 in
# 26.05 (with the LDAC decoder) breaks Bluetooth sinks (no sink / low quality / dropouts),
# so bluez/pipewire/wireplumber are pinned to the known-good 25.11. No version gate here:
# a nixpkgs bump is no proof the LDAC fix landed — check the linked issue instead.
{ nixpkgs-25-11, pkgs, ... }:

let
  pkgs-25-11 = nixpkgs-25-11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  hardware.bluetooth.package = pkgs-25-11.bluez;
  services.pipewire.package = pkgs-25-11.pipewire;
  services.pipewire.wireplumber.package = pkgs-25-11.wireplumber;
}
