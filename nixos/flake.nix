{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    on-air-plasmoid = {
      url = "github:Mendior/on-air-plasmoid";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-25-11,
      on-air-plasmoid,
    }:
    {
      nixosConfigurations.t530 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            nixpkgs-25-11
            on-air-plasmoid;
        };
        modules = [ ./configuration.nix ];
      };
    };
}