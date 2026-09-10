{ config, pkgs, lib, primaryUser, ... }:

{
  # --- SYSTEM CORE, BOOT & ULTRA PERFORMANCE TUNING ---
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Wymuszenie najnowszej gałęzi jądra dla pełnego wsparcia sched_ext
    kernelParams = [
      "preempt=full"
      "loglevel=4"
      "nowatchdog"
      # "mitigations=off" # Ryzykowne: Odzyskanie 15-30% wydajności procesora poprzez wyłączenie łat sprzętowych
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10; # SSD tylko RAM będzie na skraju wyczerpania.
      "vm.vfs_cache_pressure" = 60; # Agresywniejsze zwalnianie pamięci podręcznej dysku zamiast swapowania aplikacji
      "vm.page-cluster" = 0; # Wyłączenie czytania blokowego ze swapu. Zapobiega zamrażaniu GUI na SSD.
      "vm.watermark_scale_factor" = 125; # Płynniejsze zarządzanie pamięcią wirtualną przy intensywnym użyciu ZRAM
      "vm.zone_reclaim_mode" = 0; # Optymalizacja lokalnej alokacji stron pamięci dla CPU Ivy Bridge
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "kernel.io_uring_disabled" = 0; # Włączenie asynchronicznego I/O dla maksymalnej wydajności Podmana i edytorów kodu
    };
    extraModprobeConfig = "options btusb enable_autosuspend=0";
    initrd.kernelModules = [ "i915" ];
    blacklistedKernelModules = [
      "firewire_ohci"
      "tpm" # Wyłączenie inicjalizacji przestarzałego modułu TPM 1.2 dla szybszego bootowania
    ];
    tmp.useTmpfs = true;
    loader = {
      timeout = 1;
      grub = {
        enable = true;
        device = "/dev/sda";
        configurationLimit = 10;
      };
    };
  };

  # Wymagane, żeby hardware.cpu.intel.updateMicrocode (ustawione w
  # t530-generated-hardware-configuration.nix jako mkDefault) faktycznie się
  # włączyło — bez tego domyślna wartość to false i mikrokod Intela (ważny
  # dla stabilności i łatek Spectre/Meltdown na starym Ivy Bridge) nigdy się
  # nie ładuje.
  hardware.enableRedistributableFirmware = true;

  nix.optimise.automatic = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ primaryUser ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.journald.extraConfig = "Compress=yes\n";

  # Włączenie nowoczesnego planisty zadań eBPF zoptymalizowanego pod responsywność desktopu
  services.scx = {
    enable = true;
    scheduler = "scx_lavd"; # Wybór planisty LAVD (Latency-Critical and Audio-Visual Desktop)
  };

  # Optymalizacja systemd: wyłączenie zrzutów pamięci po awarii oraz skrócenie timeoutów (standard 26.05)
  systemd.coredump.enable = false;
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "10s";
    DefaultTimeoutStopSec = "10s";
  };

  # --- OPTYMALIZACJA PAMIĘCI (SWAP SSD) & SPRZĘTU ---
  zramSwap.enable = false; # Wyłączenie ZRAM, aby odciążyć CPU ze stałej kompresji

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 16384; # 16 GB bezpiecznego bufora na dysku SSD
  } ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
    ];
  };

  # --- GPU: NVS 5400M is Fermi (GF108). Proprietary driver is a dead end here —
  # legacy_470 dropped Fermi support, and legacy_390 (the correct branch) has
  # been marked broken in nixpkgs for years (relies on kernel APIs removed
  # around 5.17-6.1, e.g. PDE_DATA()/pci_set_dma_mask, never re-patched).
  # Sticking with nouveau; videoDrivers left at its default.

  # Zaawansowany tuning warstwy blokowej dla dysków SSD (Kyber + wyłączenie add_random)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/add_random}="0"
  '';

  services.fstrim.enable = true; # Automatyczne czyszczenie i konserwacja dysku SSD w tle
}
