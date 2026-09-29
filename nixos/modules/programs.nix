{ pkgs, primaryUser, ... }:

{
  # --- VIRTUALIZATION & DOCKER ---
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ]; # also cache and stale images
    };
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # --- BUILT-IN PROGRAMS & SERVICES ---
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
    # Not a plain package: the module also opens TCP/UDP 1714-1764, without
    # which pairing silently fails.
    kdeconnect.enable = true;
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
        # Resolves inside FHS sandboxes (vscode.fhs); a direct /etc/git path dangles there.
        includeIf = {
          "hasconfig:remote.*.url:git@github.com:Gee-Bee/**"        = { path = "/etc/static/git/config.private"; };
          "hasconfig:remote.*.url:https://github.com/Gee-Bee/**"    = { path = "/etc/static/git/config.private"; };
        };
      }
      {
        # /etc/git is not visible inside FHS sandboxes; /etc/static is.
        core.excludesFile = "/etc/static/git/gitignore-global";
      }
    ];
  };
  environment.etc."git/gitignore-global".text = ''
    .freebuff/
  '';
  environment.etc."git/config.private".text = ''
    [user]
    	name = Gee-Bee
    	email = greg.bunia@gmail.com
  '';
  # Resolves inside FHS sandboxes (vscode.fhs); a direct /etc/gitconfig target dangles there.
  systemd.tmpfiles.rules = [
    "L+ /home/${primaryUser}/.gitconfig - - - - /etc/static/gitconfig"
  ];

  # --- SYSTEM PACKAGES ---
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
