# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, nixpkgs-25-11, ... }:

let
  pkgs-25-11 = nixpkgs-25-11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./t530-hardware-configuration.nix
    ];

#   swapDevices = [ {
#     device = "/var/lib/swapfile";
#     size = 16*1024;
#   } ];
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Najlepszy kompresor dla systemów desktopowych
    memoryPercent = 50; # Wykorzysta maksymalnie połowę Twojego RAMu na skompresowany swap
  };


   # Bootloader i parametry startowe jądra (Scalone)
  boot = {
    loader = {
      timeout = 1;
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };

    # Parametry jądra (Voluntary odciąża procesor T530 w porównaniu do preempt=full)
    kernelParams = [ "preempt=voluntary" "loglevel=4" ];

    # Wyłączenie oszczędzania energii dla stabilności Broadcom Bluetooth
    extraModprobeConfig = ''
      options btusb enable_autosuspend=0
    '';
  };

  networking.hostName = "t530"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
# USUNIĘTO: networking.networkmanager.plugins = ... (NixOS robi to teraz automatycznie)
#   networking.networkmanager.plugins = [
#     pkgs.networkmanager-openvpn
#   ];

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  #services.displayManager.cosmic-greeter.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;
  #services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  #services.desktopManager.cosmic.enable = true;
  services.displayManager.defaultSession = "plasmax11";

  # Enable the Budgie Desktop Environment.
  #services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.budgie.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gb = {
    isNormalUser = true;
    description = "GB";
    linger = true;
    extraGroups = [ "networkmanager" "wheel" "libvirtd"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;

  };

  # List services that you want to enable:
# Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  system.autoUpgrade = {
    enable = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true; # Automatycznie usuwa nieużywane kontenery i sieci
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "65535"; }
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  hardware = {
    # Aktualizacja mikrokodu procesora Intel dla stabilności ACPI/MTRR
    cpu.intel.updateMicrocode = true;

    graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver     # Współczesny sterownik dla nowszych procesorów (warto zostawić)
      intel-vaapi-driver     # dla grafiki HD 4000 w Ivy Bridge
    ];
  };

    # Sterowniki i oprogramowanie układowe (Firmware)
    enableAllFirmware = true;
    firmware = [ pkgs.broadcom-bt-firmware ];

    # Podsystem Bluetooth
    bluetooth = {
      enable = true;
      # 3 paczki z wersji 25.11: bluez, wireplumber, pipewire (regresja z high fidelity playback )
      package = pkgs-25-11.bluez;
      powerOnBoot = true;
    };
  };

  # Wsparcie dla RTKit (wymagane przez PipeWire dla zachowania priorytetu procesów audio)
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    package = pkgs-25-11.pipewire;
    wireplumber = {
      enable = true;
      package = pkgs-25-11.wireplumber;
    };

    # Emulacja systemów audio (ALSA, PulseAudio i JACK za pomocą PipeWire)
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.sudo.extraRules= [
    { groups = [ "wheel" ];
      commands = [ { command = "ALL" ; options= [ "NOPASSWD" ]; } ];
    }
  ];

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true; vimAlias = true;
    };
    git = {
      enable = true;
      package = pkgs.gitFull;
      config = {
        user.name = "Grzegorz Bunia";
        user.email = "g.bunia@american-systems.pl";
      };
    };
    firefox.enable = true;
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting ""
      '';
      shellAliases = {
        nix-up = "sudo nixos-rebuild switch --flake ~/src/dotfiles/nixos/#t530";
        nix-test = "sudo nixos-rebuild dry-activateb --flake ~/src/dotfiles/nixos/#t530";
      };
    };
    #kdeconnect.enable = true;
    starship = {
      enable = true;
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

  # Wyłączenie indeksowania plików Baloo i usług Akonadi
  environment.etc."xdg/baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=false
  '';

  # Blokada autostartu Akonadi dla wszystkich użytkowników
  environment.extraInit = ''
    export AKONADI_INSTANCE_SERVER_SELF_START=false
  '';

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # fix VsCode, Chrome blurry fonts in Wayland; https://github.com/NixOS/nixpkgs/commit/b2eb5f62a7fd94ab58acafec9f64e54f97c508a6
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    htop
    gnumake
    vscode
    #devcontainer
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
    android-tools scrcpy
    qtpass pinentry-qt
    pass
    lazygit git-cola gitui
    docker-buildx
    screenkey showmethekey
    ffmpeg
#    broadcom-bt-firmware
    pwvucontrol
  ];

  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;
  #virtualisation.virtualbox.guest.enable = true;
  #virtualisation.virtualbox.guest.dragAndDrop = true;
  #users.extraGroups.vboxusers.members = [ "gb" ];

  nix.settings = {
    # Włączenie nowoczesnej komendy 'nix' oraz obsługi Flakes
    experimental-features = [ "nix-command" "flakes" ];
  };
}
