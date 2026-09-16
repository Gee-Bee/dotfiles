{ config, pkgs, freebuff-cli-src, freebuff-desktop-src, ... }:

let
  # "-baseline" build: T530 (Ivy Bridge) has no AVX2, and freebuff's default
  # linux-x64 binary hard-crashes with SIGILL there (upstream:
  # CodebuffAI/freebuff #497, #654, #765, #1288).
  freebuff-cli = pkgs.stdenv.mkDerivation {
    pname = "freebuff-cli";
    version = "unstable"; # actual version is pinned via the src URL in flake.nix
    src = freebuff-cli-src;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 freebuff $out/bin/freebuff
      runHook postInstall
    '';

    meta.mainProgram = "freebuff";
  };

  # No AVX2-baseline build of the desktop app exists for Linux upstream
  # (only Windows has one — CodebuffAI/freebuff #949, #983).
  freebuff-desktop = pkgs.appimageTools.wrapType2 {
    pname = "freebuff-desktop";
    version = "unstable"; # actual version is pinned via the src URL in flake.nix
    src = freebuff-desktop-src;
  };
in
{
  # --- LOCAL AI ENGINE (OLLAMA OPTIMIZED FOR CPU) ---
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    openFirewall = false;
    package = pkgs.ollama-cpu;
    loadModels = [
      "qwen2.5-coder:0.5b-base" # tab completion, 0.5B
      "qwen2.5-coder:1.5b-instruct" # chat/refactor
    ];
  };

  # --- TERMINALOWY I DESKTOPOWY AGENT KODUJĄCY (FREEBUFF, DARMOWY) ---
  environment.systemPackages = [
    freebuff-cli
    freebuff-desktop
  ];
}