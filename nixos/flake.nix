{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    on-air-plasmoid = {
      url = "github:Mendior/on-air-plasmoid";
      flake = false;
    };
    # Claude Desktop + Claude Code CLI; packages expose a single hard-coded
    # version per commit, bumped by `nix flake lock --update-input llm-agents`.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Freebuff CLI and Desktop are separate, independently-versioned release trains (no flake).
    # Bump: edit the version in the URL, then `nix flake lock --update-input <name>`.
    # check versions with: `git ls-remote --tags https://github.com/CodebuffAI/codebuff-community | grep freebuff | awk '{print $2}' | sort -V`
    freebuff-cli-src = {
      url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-v0.0.204/freebuff-linux-x64-baseline.tar.gz";
      flake = false;
    };
    freebuff-desktop-src = {
      url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-desktop-v0.0.151/Freebuff-0.0.151-linux-x86_64.AppImage";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-25-11,
      on-air-plasmoid,
      llm-agents,
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
            llm-agents
            freebuff-cli-src
            freebuff-desktop-src
          ;
        };
        modules = [ ./configuration.nix ];
      };
    };
}