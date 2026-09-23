{ pkgs, freebuff-cli-src, freebuff-desktop-src, llm-agents, ... }:

let
  # "-baseline" build: T530 (Ivy Bridge) has no AVX2 — the default binary dies with SIGILL
  # (CodebuffAI/freebuff #497, #654, #765, #1288).
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
  # Overlay from llm-agents builds the packages against THIS system's pkgs
  # (shared libs, our allowUnfree); the flake's own packages would instead
  # drag in a second ~1 GiB nixpkgs-unstable closure.
  nixpkgs.overlays = [ llm-agents.overlays.shared-nixpkgs ];

  # --- LOCAL AI ENGINE (OLLAMA, CPU-ONLY) ---
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

  # --- AI CODING AGENTS (FREEBUFF + CLAUDE) ---
  environment.systemPackages = [
    freebuff-cli
    freebuff-desktop
    # FHS wrapper also runs the generic binaries the app downloads at runtime
    pkgs.llm-agents.claude-desktop # chat works on free accounts; project features need Pro/Max on the account
    pkgs.llm-agents.claude-code # for repo work: terminal or a VS Code extension, not the desktop app
  ];
}