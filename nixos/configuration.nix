{ config, pkgs, lib, nixpkgs-25-11, ... }:

let
  # Błyskawiczny import pakietów 25.11 z Flake'a bez pobierania przez fetchTarball
  pkgs-25-11 = nixpkgs-25-11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./t530-hardware-configuration.nix
  ];

  # --- SYSTEM CORE & BOOT ---
  boot = {
    kernelParams = [
      "preempt=voluntary"
      "loglevel=4"
    ];
    extraModprobeConfig = "options btusb enable_autosuspend=0";
    initrd.kernelModules = [ "i915" ]; # Wczesne ładowanie sterownika wideo dla grafiki Intel HD 4000
    loader = {
      timeout = 1;
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org).
  system.stateVersion = "24.05"; # Did you read the comment?

  time.timeZone = "Europe/Warsaw";

  # --- LOKALIZACJA I KLAWIATURA ---
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "pl_PL.UTF-8";
      LC_IDENTIFICATION = "pl_PL.UTF-8";
      LC_MEASUREMENT = "pl_PL.UTF-8";
      LC_MONETARY = "pl_PL.UTF-8";
      LC_NAME = "pl_PL.UTF-8";
      LC_NUMERIC = "pl_PL.UTF-8";
      LC_PAPER = "pl_PL.UTF-8";
      LC_TELEPHONE = "pl_PL.UTF-8";
      LC_TIME = "pl_PL.UTF-8";
    };
  };
  console.keyMap = "pl2";
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  # --- INTERFEJS GRAFICZNY (PLASMA 6) ---
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasmax11"; # Wymuszenie sesji X11 dla stabilności na starszym GPU

  # --- SIEĆ I USŁUGI ---
  networking.hostName = "t530";
  networking.networkmanager.enable = true;
  services.printing.enable = false;
  services.pcscd.enable = false;
  services.fstrim.enable = true; # Automatyczne czyszczenie i konserwacja dysku SSD w tle

  # --- MULTIMEDIA, AUDIO (DOWNGRADE DO 25.11) & BLUETOOTH ---
  security.rtkit.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    package = pkgs-25-11.bluez;
  };

  services.pipewire = {
    enable = true;
    package = pkgs-25-11.pipewire;
    wireplumber.package = pkgs-25-11.wireplumber;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # --- PROFILE UŻYTKOWNIKÓW & ZABEZPIECZENIA ---
  nixpkgs.config.allowUnfree = true;
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  users.users.gb = {
    isNormalUser = true;
    description = "GB";
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
    ];
  };

  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "65535"; }
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  # --- WIRTUALIZACJA I DOCKER ---
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # --- OPTYMALIZACJA PAMIĘCI (ZRAM) & SPRZĘTU ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  hardware.enableAllFirmware = true;
  hardware.firmware = [ pkgs.broadcom-bt-firmware ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  # --- OPTYMALIZACJE ŚRODOWISKA GRAFICZNEGO (BEZ INDEKSOWANIA BALOO/AKONADI) ---
  environment.etc."xdg/baloofilerc".text = "[Basic Settings]\nIndexing-Enabled=false\n";
  environment.extraInit = "export AKONADI_INSTANCE_SERVER_SELF_START=false\n";
  environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };

  # --- PROGRAMY I USŁUGI WBUDOWANE ---
  programs = {
    mtr.enable = true;
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
    git = {
      enable = true;
      package = pkgs.gitFull;
      config = {
        user.name = "Grzegorz Bunia";
        user.email = "g.bunia@american-systems.pl";
      };
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

  # --- LISTA PAKIETÓW SYSTEMOWYCH ---
  environment.systemPackages = with pkgs; [
    htop
    gnumake
    vscode
    zed-editor
    firefox-devedition
    google-chrome
    lshw
    kdePackages.yakuake
    kdePackages.kate
    kdePackages.qtmultimedia
    kdePackages.qtwebengine
    kdePackages.krdc
    mpv
    nerd-fonts.hack
    vokoscreen-ng
    postman
    android-tools
    scrcpy
    qtpass
    pinentry-qt
    pass
    lazygit
    git-cola
    gitui
    docker-buildx
    screenkey
    showmethekey
    ffmpeg
    pwvucontrol
  ];
}
