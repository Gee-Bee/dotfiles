{ config, pkgs, primaryUser, ... }:

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
          "hasconfig:remote.*.url:git@github.com:Gee-Bee/**"        = { path = "/etc/git/config.private"; };
          "hasconfig:remote.*.url:https://github.com/Gee-Bee/**"    = { path = "/etc/git/config.private"; };
        };
      }
    ];
  };
  environment.etc."git/config.private".text = ''
    [user]
    	name = Gee-Bee
    	email = greg.bunia@gmail.com
  '';
  systemd.tmpfiles.rules = [
    "L+ /home/${primaryUser}/.gitconfig - - - - /etc/gitconfig"
  ];

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
