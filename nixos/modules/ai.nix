{ config, pkgs, llm-agents, ... }:

let
  llm-agents-pkgs = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # --- LOCAL AI ENGINE (OLLAMA OPTIMIZED FOR CPU) ---
  services.ollama = {
    enable = true;

    host = "0.0.0.0";
    port = 11434;
    openFirewall = false;

    package = pkgs.ollama-cpu;

    # Oficjalne, poprawne nazwy modeli z rejestru Ollama:
    loadModels = [
      # 1. AUTOUZUPEŁNIANIE KODU (FIM / Tab completion)
      "qwen2.5-coder:0.5b-base" # Błyskawiczny (0.5B), niemal natychmiastowe podpowiedzi
      # 2. CZAT, EDYCJA I REFAKTORYZACJA (Twinny Chat)
      "qwen2.5-coder:1.5b-instruct"
    ];
  };

  # --- TERMINALOWY AGENT KODUJĄCY (CHMURA, DARMOWY) ---
  # freebuff does not use the local Ollama above — separate tools.
  # Local-model support exists only as an unmerged PR upstream:
  # https://github.com/CodebuffAI/codebuff/pull/693
  environment.systemPackages = [
    llm-agents-pkgs.freebuff
  ];
}