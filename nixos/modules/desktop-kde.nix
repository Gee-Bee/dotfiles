{ config, pkgs, ... }:

{
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

  # --- OPTYMALIZACJE ŚRODOWISKA GRAFICZNEGO (BEZ INDEKSOWANIA BALOO/AKONADI) ---
  environment.sessionVariables = {
    GLIBC_TUNABLES = "glibc.malloc.tcache_max=65536"; # Szybsza alokacja pamięci w aplikacjach GUI
  };
  environment.extraInit = "export AKONADI_INSTANCE_SERVER_SELF_START=false\n";
  environment.etc."xdg/baloofilerc".text = "[Basic Settings]\nIndexing-Enabled=false\n";

  # Domyślne ustawienia KWin dopasowane do słabego iGPU (Intel HD 4000, Ivy Bridge).
  # To są WARTOŚCI DOMYŚLNE — jeśli GUI System Settings zapisze własną wartość
  # do ~/.config/kwinrc, ten plik przestaje obowiązywać dla danego klucza.
  environment.etc."xdg/kwinrc".text = ''
    [Compositing]
    # OpenGL zamiast XRender — stabilniejsze niż Xrender na i915, zmienić gdy będą artekfakty/tearing
    Backend=OpenGL
    # 5 = Never — wyłącza generowanie miniatur okien na pasku zadań (oszczędność CPU/RAM)
    HiddenPreviews=5

    [Plugins]
    # Blur i Background Contrast to dwa najcięższe efekty na starym iGPU — wyłączone
    blurEnabled=false
    contrastEnabled=false
    # Czysto kosmetyczne, bez wpływu na użyteczność — można bezpiecznie wyłączyć
    wobblywindowsEnabled=false
    magiclampEnabled=false
    slideEnabled=false
  '';

  # Domyślna szybkość animacji: 0 = natychmiast, 1 = domyślna (Plasma standard).
  environment.etc."xdg/kdeglobals".text = ''
    [KDE]
    AnimationDurationFactor=0.5

    [KFileDialog Settings]
    Automatically select filename extension=true
    Show Preview=false
  '';
}
