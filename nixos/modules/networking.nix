{ pkgs, ... }:

{
  # --- NETWORK ---
  networking.hostName = "t530";
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # Wi-Fi sleep causes ping spikes and caps throughput
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };
}
