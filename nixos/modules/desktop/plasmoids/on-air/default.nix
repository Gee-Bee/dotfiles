{ pkgs, on-air-plasmoid, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ./package.nix { inherit on-air-plasmoid; })
  ];
}