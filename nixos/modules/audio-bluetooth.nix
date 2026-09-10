{ config, pkgs, nixpkgs-25-11, ... }:

let
  pkgs-25-11 = nixpkgs-25-11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # rtkit daje wątkom audio (pipewire/jack) uprawnienia real-time bez roota —
  # tu, a nie w networking.nix, bo to wyłącznie kwestia audio, nie sieci.
  security.rtkit.enable = true;

  # --- BLUETOOTH & AUDIO ---
  #
  # UWAGA: bluez, pipewire i wireplumber są CELOWO przypięte do kanału
  # nixos-25.11, mimo że reszta systemu jedzie na 26.05.
  #
  # Powód: regresja w wireplumber 0.5.14 (paczka trafiła do 26.05 razem z
  # dekoderem LDAC) powoduje, że słuchawka/głośnik Bluetooth (u mnie Soundcore
  # Motion+) łączy się poprawnie, ale nie pojawia się jako sink audio /
  # gra w niskiej jakości / dźwięk się urywa. To nie jest problem lokalny —
  # potwierdzone w wątkach na NixOS Discourse:
  #   - https://discourse.nixos.org/t/bluetooth-audio-stopped-working-after-26-05-upgrade/78701
  #   - https://discourse.nixos.org/t/bluetooth-audio-broken-after-recent-update-likely-ldac-pipewire-1-6-2/76805
  #
  # JAK SPRAWDZIĆ, CZY MOŻNA JUŻ ODPIĄĆ TEN WORKAROUND:
  #   1. Sprawdź powyższe wątki — zwykle ktoś potwierdzi wersję pipewire/
  #      wireplumber, w której naprawiono LDAC fallback.
  #   2. Porównaj wersje w obu kanałach:
  #        nix eval github:NixOS/nixpkgs/nixos-26.05#wireplumber.version
  #        nix eval github:NixOS/nixpkgs/nixos-25.11#wireplumber.version
  #      Jeśli 26.05 ma nowszą wersję niż ta, na której teraz stoisz na 25.11
  #      (sprawdź w flake.lock), prawdopodobnie zawiera fix.
  #   3. Przeszukaj issues/PR w nixpkgs pod kątem "LDAC" / "bluez5" / "Motion+":
  #        https://github.com/NixOS/nixpkgs/issues?q=wireplumber+bluetooth+LDAC
  #   4. Przed odpięciem przetestuj tymczasowo (bez commitowania): podmień
  #      `pkgs-25-11.wireplumber` z powrotem na `pkgs.wireplumber` na gałęzi
  #      testowej i posłuchaj, czy Motion+ znowu gra poprawnie.
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
