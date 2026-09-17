{ pkgs, ... }:

let
  # Restores per-user KDE config to the /etc/xdg system defaults; run from a TTY after logout.
  # Extra files: kde-reset plasma-org.kde.plasma.desktop-appletsrc
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
  # --- LOCALE & KEYBOARD ---
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

  # --- GRAPHICAL INTERFACE (PLASMA 6) ---
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasmax11"; # X11 forced for stability on the old GPU

  # --- GRAPHICAL ENV OPTIMIZATIONS (NO BALOO/AKONADI INDEXING) ---
  environment.sessionVariables = {
    GLIBC_TUNABLES = "glibc.malloc.tcache_max=65536"; # faster allocations in GUI apps
  };
  environment.extraInit = "export AKONADI_INSTANCE_SERVER_SELF_START=false\n"; # keep Akonadi from self-starting (PIM unused)
  environment.etc."xdg/baloofilerc".text = "[Basic Settings]\nIndexing-Enabled=false\n";

  # KWin defaults tuned for the weak iGPU (Intel HD 4000). A user-side ~/.config/kwinrc
  # overrides these keys; kde-reset restores them.
  environment.etc."xdg/kwinrc".text = ''
    [Compositing]
    # OpenGL instead of XRender — more stable on i915; revisit on artifacts/tearing
    Backend=OpenGL
    # 5 = Never — no taskbar window previews (CPU/RAM)
    HiddenPreviews=5

    [Plugins]
    # the two heaviest effects on this iGPU
    blurEnabled=false
    contrastEnabled=false
    # cosmetic, no usability impact
    wobblywindowsEnabled=false
    magiclampEnabled=false
    slideEnabled=false

    [TabBox]
    # 1 = OnlyCurrentScreenClients: Alt+Tab limited to windows on the active screen
    MultiScreenMode=1

    [Desktops]
    # Explicit layout — ksmserver restores saved windows only when the desktop topology is unambiguous
    Number=2
    Rows=2
  '';

  # Default animation speed: 0 = instant, 1 = Plasma standard.
  environment.etc."xdg/kdeglobals".text = ''
    [KDE]
    AnimationDurationFactor=0.5

    [KScreen]
    # Global scale — on X11 KScreen stores it only in ~/.config/kdeglobals, so kde-reset
    # would clear it to 1.0; monitor placement lives in ~/.local/share/kscreen (untouched).
    ScaleFactor=1.25
    ScreenScaleFactors=LVDS-1=1.25;DP-2=1.25;DP-3=1.25;
    XwaylandClientsScale=false

    [KFileDialog Settings]
    Automatically select filename extension=true
    Show Preview=false
    # Lost on kde-reset (KDE defaults: Name/false)
    Breadcrumb Navigation=true
    Sort by=Date
  '';

  # KDE bug 442380 (X11 only): systemd-based session start races kwin_x11 window restoration,
  # landing windows on the active desktop instead of the saved one. Sequential start fixes it.
  environment.etc."xdg/startkderc".text = ''
    [General]
    systemdBoot=false
  '';

  # Explicit previous-session restore. A user-side ~/.config/ksmserverrc overrides this key —
  # kde-reset removes it.
  environment.etc."xdg/ksmserverrc".text = ''
    [General]
    loginMode=restorePreviousLogout
  '';

  environment.systemPackages = [ kdeReset ];
}
