{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    on-air-plasmoid = {
      url = "github:Mendior/on-air-plasmoid";
      flake = false;
    };
    # Freebuff CLI and Desktop are separate, independently-versioned release
    # trains (no flake). To bump: edit the version in the URL below, then
    # `nix flake lock --update-input <name>` to fetch and pin the new hash.
    freebuff-cli-src = {
      url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-v0.0.173/freebuff-linux-x64-baseline.tar.gz";
      flake = false;
    };
    freebuff-desktop-src = {
      url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-desktop-v0.0.106/Freebuff-0.0.106-linux-x86_64.AppImage";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-25-11,
      on-air-plasmoid,
      freebuff-cli-src,
      freebuff-desktop-src,
    }:
    {
      nixosConfigurations.t530 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            nixpkgs-25-11
            on-air-plasmoid
            freebuff-cli-src
            freebuff-desktop-src
          ;
        };
        modules = [ ./configuration.nix ];
      };
    };
}