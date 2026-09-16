# AGENTS.md — zasady dla asystentów AI pracujących w tym repo

## Komentarze
- Komentarz uzasadnia decyzję (dlaczego tak), nie opisuje oczywistego "co robi kod".
- Każdy komentarz jest atomowy i samowystarczalny: czytelnik pliku nie zna
  historii git, diffów ani wcześniejszych rozmów. Zakaz fraz typu
  "bez zmian", "przywrócone", "tymczasowe", "wcześniej", "wg dyskusji".
- Maksymalnie zwięzłe i tylo tam, gdzie niezbędne.
- Język polski, nazwy techniczne po angielsku.

## Nix / NixOS
- Flake w nixos/, bez Home Managera.
- Konfig per-user KDE: systemowe domyślne przez environment.etc."xdg/..." +
  narzędzie kde-reset (czyści ~/.config). Nie wprowadzać zapisów wprost do home.
- Skrypty: fish, przez pkgs.writers.writeFishBin (bez ręcznego shebanga);
  w unitach systemd odwołania przez lib.getExe.
- Zewnętrzne narzędzia w skryptach tylko po ścieżkach ${pkgs.x}/bin/...
- Minimalne, celowe diffy — refaktoryzacja tylko, gdy jest częścią zadania.
