{ pkgs, primaryUser, ... }:

{
  # --- SYSTEM CORE, BOOT & PERFORMANCE TUNING ---
  boot = {
    # mitigations=off rejected: 15-30% CPU gain not worth disabling hardware vulnerability mitigations
    kernelParams = [
      "preempt=full"
      "loglevel=4"
      "nowatchdog"
    ];
    kernelPackages = pkgs.linuxPackages_latest; # latest kernel branch for full sched_ext support
    kernel.sysctl = {
      "vm.swappiness" = 10; # swap only when RAM is nearly exhausted
      "vm.vfs_cache_pressure" = 60; # prefer reclaiming FS caches over swapping applications
      "vm.page-cluster" = 0; # no swap readahead — prevents GUI freezes when swapping on SSD
      "vm.watermark_scale_factor" = 125; # smoother reclaim under memory pressure
      "vm.zone_reclaim_mode" = 0; # keep NUMA-local page allocation on Ivy Bridge
      "net.core.default_qdisc" = "fq"; # required by bbr
      "net.ipv4.tcp_congestion_control" = "bbr";
      "kernel.io_uring_disabled" = 0; # async I/O for container workloads and editors
    };
    extraModprobeConfig = "options btusb enable_autosuspend=0"; # autosuspend drops Bluetooth audio devices
    initrd.kernelModules = [ "i915" ];
    blacklistedKernelModules = [
      "firewire_ohci"
      "tpm" # deprecated TPM 1.2 — init slows boot
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

  # Required for hardware.cpu.intel.updateMicrocode (mkDefault in the hardware config) to take
  # effect — without it Intel microcode (Spectre/Meltdown fixes on Ivy Bridge) never loads.
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

  # eBPF scheduler tuned for desktop responsiveness; LAVD targets latency-critical workloads
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # systemd-coredump: no cost in normal operation, capped space (256M/dump, 512M total);
  # when disabled, the kernel instead writes raw core.<PID> dumps straight into $HOME.
  systemd.coredump = {
    enable = true;
    settings.Coredump = {
      ProcessSizeMax = "256M";
      ExternalSizeMax = "256M";
      MaxUse = "512M";
      KeepFree = "1G";
    };
  };

  # Shorter unit start/stop timeouts than the 90s default.
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "10s";
    DefaultTimeoutStopSec = "10s";
  };

  # --- MEMORY (SWAP ON SSD) & HARDWARE ---
  zramSwap.enable = false; # constant compression cost not worth it on this CPU

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 16384; # OOM safety buffer on SSD
  } ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
    ];
  };

  # NVS 5400M is Fermi: legacy_470 dropped it and legacy_390 (the correct branch) has been
  # broken in nixpkgs for years — nouveau with default videoDrivers is the only workable option.

  # SSD block-layer tuning: kyber scheduler, no entropy contribution from disk reads
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/add_random}="0"
  '';

  services.fstrim.enable = true;
}
