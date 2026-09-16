{ config, pkgs, ... }:

let
  # kde-reset: przywraca per-user konfig KDE do systemowych domyślnych
  # z /etc/xdg. Uruchamiać z TTY po wylogowaniu (Plasma nie może działać).
  # Reset panelu: kde-reset plasma-org.kde.plasma.desktop-appletsrc
  kdeReset = pkgs.writers.writeFishBin "kde-reset" ''
    ${pkgs.procps}/bin/pgrep -x plasmashell >/dev/null
    and echo "Plasma działa — uruchom z TTY."
    and exit 1

    set backup "$HOME/.config/kde-backup/"(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)
    ${pkgs.coreutils}/bin/mkdir -p "$backup"; or exit 1

    for f in kwinrc kdeglobals ksmserverrc startkderc baloofilerc $argv
      set path "$HOME/.config/$f"
      test -e "$path"; and ${pkgs.coreutils}/bin/mv "$path" "$backup/"
    end

    test -d "$HOME/.config/session"
    and ${pkgs.coreutils}/bin/mv "$HOME/.config/session" "$backup/"

    echo "Przeniesione do $backup — zaloguj się ponownie."
  '';
in
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

    [TabBox]
    # 1 = OnlyCurrentScreenClients (enum ClientMultiScreenMode w KWin): Alt+Tab
    # obejmuje tylko okna z aktywnego ekranu
    MultiScreenMode=1

    [Desktops]
    # Jawny układ: 2 pulpity w pionie — ksmserver przywraca okna tylko wtedy,
    # gdy topologia desktopów jest jednoznaczna
    Number=2
    Rows=2
  '';

  # Domyślna szybkość animacji: 0 = natychmiast, 1 = domyślna (Plasma standard).
  environment.etc."xdg/kdeglobals".text = ''
    [KDE]
    AnimationDurationFactor=0.5

    [KScreen]
    # Skala globalna: na X11 KScreen zapisuje ją wyłącznie w ~/.config/kdeglobals,
    # więc kde-reset kasuje ją do 1.0. Rozmieszczenie monitorów leży w
    # ~/.local/share/kscreen i przez reset nie jest dotykane.
    ScaleFactor=1.25
    ScreenScaleFactors=LVDS-1=1.25;DP-2=1.25;DP-3=1.25;
    XwaylandClientsScale=false

    [KFileDialog Settings]
    Automatically select filename extension=true
    Show Preview=false
    # Preferencje tracone przy kde-reset (domyślne KDE to Name/false)
    Breadcrumb Navigation=true
    Sort by=Date
  '';

  # Bug KDE 442380 (tylko X11): start sesji przez systemd wyściguje kwin_x11
  # przy przywracaniu okien — lądują na aktywnym pulpicie zamiast zapisanego.
  # Sekwencyjny start eliminuje wyścig; ~/.config/startkderc nadpisuje per-user.
  environment.etc."xdg/startkderc".text = ''
    [General]
    systemdBoot=false
  '';

  # Jawny tryb przywracania poprzedniej sesji; zapis w ~/.config/ksmserverrc
  # nadpisuje ten klucz — usuwa go kde-reset.
  environment.etc."xdg/ksmserverrc".text = ''
    [General]
    loginMode=restorePreviousLogout
  '';

  environment.systemPackages = [ kdeReset ];
}
