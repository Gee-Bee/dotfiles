{ pkgs, nixpkgs-25-11, ... }:

let
  pkgs-25-11 = nixpkgs-25-11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # rtkit grants real-time scheduling to pipewire/jack threads without root
  security.rtkit.enable = true;

  # --- BLUETOOTH & AUDIO ---
  # bluez/pipewire/wireplumber pinned to 25.11: wireplumber 0.5.14 in 26.05 (with the LDAC decoder)
  # breaks Bluetooth sinks (no sink / low quality / dropouts) — search nixpkgs issues "wireplumber LDAC" to unpin.
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
}
