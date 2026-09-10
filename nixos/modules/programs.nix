{ config, pkgs, ... }:

{
  # --- WIRTUALIZACJA I DOCKER ---
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ]; # też cache i stare obrazy
    };
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # --- LOCAL AI ENGINE (OLLAMA OPTIMIZED FOR CPU) ---
  services.ollama = {
    enable = true;

    host = "0.0.0.0";
    port = 11434;
    openFirewall = false;

    package = pkgs.ollama-cpu;

    # Oficjalne, poprawne nazwy modeli z rejestru Ollama:
    loadModels = [
      # 1. AUTOUZUPEŁNIANIE KODU (FIM / Tab completion)
      "qwen2.5-coder:0.5b-base" # Błyskawiczny (0.5B), niemal natychmiastowe podpowiedzi
      # 2. CZAT, EDYCJA I REFAKTORYZACJA (Twinny Chat)
      "qwen2.5-coder:1.5b-instruct"
    ];
  };

  # --- PROGRAMY I USŁUGI WBUDOWANE ---
  programs = {
    firefox.enable = true;
    starship.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
    fish = {
      enable = true;
      interactiveShellInit = ''set fish_greeting ""'';
      shellAliases = {
        nix-up   = "sudo nixos-rebuild switch --flake ~/src/dotfiles/nixos/#t530";
        nix-test = "sudo nixos-rebuild test --flake ~/src/dotfiles/nixos/#t530";
      };
    };
    tmux = {
      enable = true;
      baseIndex = 1;
      plugins = with pkgs.tmuxPlugins; [
        resurrect
        power-theme
      ];
      extraConfig = ''
        set -g default-shell ${pkgs.fish}/bin/fish
        set -g @tmux_power_theme 'default'
        run-shell ${pkgs.tmuxPlugins.power-theme}/share/tmux-plugins/power/tmux-power.tmux
      '';
    };
  };
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    # Passing a list preserves the exact section order in /etc/gitconfig
    config = [
      {
        user.name = "Grzegorz Bunia";
        user.email = "g.bunia@american-systems.pl";
      }
      {
        includeIf = {
          "gitdir/i:**/src/_priv/**"     = { path = "/etc/git/config.private"; };
          "gitdir/i:**/src/{.,}dotfiles/**" = { path = "/etc/git/config.private"; };
        };
      }
    ];
  };
  environment.etc."git/config.private".text = ''
    [user]
    	name = Gee-Bee
    	email = greg.bunia@gmail.com
  '';

  # --- LISTA PAKIETÓW SYSTEMOWYCH ---
  environment.systemPackages = with pkgs; [
    htop
    gnumake
    vscode.fhs
    firefox-devedition
    google-chrome
    lshw
    kdePackages.yakuake
    kdePackages.kate
    kdePackages.qtmultimedia
    kdePackages.krdc
    mpv
    nerd-fonts.hack
    vokoscreen-ng
    postman
    android-tools
    scrcpy
    qtpass
    pass
    docker-buildx
    showmethekey
    ffmpeg
    pwvucontrol
  ];
}
