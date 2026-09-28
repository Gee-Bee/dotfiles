{
  description = "Pixel 3a phone server via Nix-on-Droid";

  inputs = {
    # Master, not release-24.05: the hardcoded proot-static path of the 24.05
    # branch is absent from every substituter (realisation impossible even on
    # the phone); master's copy is signed on nix-on-droid.cachix.org.
    # Both branches pin the same nixpkgs rev (5d874ac, 2024-02).
    nixpkgs.url = "github:NixOS/nixpkgs/5d874ac46894c896119bce68e758e9e80bdb28f1";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-on-droid }: {
    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        # HA closure on this pin carries openssl 1.1 (EOL, marked insecure);
        # explicit permit is the price of the only prebuilt HA for aarch64.
        config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
      };
      # Full evaluation requires building the aarch64 ids.nix drv (IFD) —
      # trivial on the phone, impossible from x86 without binfmt emulation.
      modules = [ ./nix-on-droid.nix ];
    };
  };
}
