{ ... }:

{
  # rtkit grants real-time scheduling to pipewire/jack threads without root
  security.rtkit.enable = true;

  # --- BLUETOOTH & AUDIO ---
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
