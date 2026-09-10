{ config, pkgs, ... }:

{
  # --- SIEĆ ---
  networking.hostName = "t530";
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # Wyłączenie uśpienia Wi-Fi dla stabilnego pingu i pełnej przepustowości sieci
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };
}
