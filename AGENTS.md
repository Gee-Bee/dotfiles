# AGENTS.md — zasady dla asystentów AI pracujących w tym repo

## Kod
- Czytelność ponad zwięzłość: nazwy opisowe, zero martwego kodu. Kod ma być zrozumiały bez komentarza.
- Najprostsze rozwiązanie spełniające zadanie: bez abstrakcji, opcji i zabezpieczeń na zapas.
- Duplikację tekstu zastąp zmienną lub funkcją pomocniczą; zła abstrakcja jest gorsza od duplikatu.
- Nie koduj ponad zadanie — dodatkowe usprawnienia zgłaszaj, nie wdrażaj.
- Styl istniejącego pliku wygrywa z preferencjami; naruszenia powyższych zasad w dotykanym kodzie poprawiaj od razu, poza dotykanym kodem — tylko zgłoś.
- Przed pokazaniem przejrzyj kod raz pod kątem powyższych zasad i sprawdź składnię (np. eval); testy i dłuższe buildy zostaw użytkownikowi.

## Komentarze
- Komentarz uzasadnia decyzję (dlaczego tak), nie opisuje oczywistego "co robi kod".
- Każdy komentarz jest atomowy i samowystarczalny: czytelnik pliku nie zna historii git, diffów ani wcześniejszych rozmów. Zakaz fraz typu "bez zmian", "przywrócone", "tymczasowe", "wcześniej", "wg dyskusji".
- Zwięzłość: domyślnie 1 linia, maksymalnie 2. Jeśli treść się nie mieści — skróć do jednej decyzji, nie tłumacz mechanizmu. Komentarz tylko tam, gdzie kod sam się nie tłumaczy.
- Po angielsku.

## Nix / NixOS
- Flake w nixos/, bez Home Managera.
- Nieużywane argumenty modułów usuwaj; wartości użyte w więcej niż jednym miejscu trafiają do `let`.
- Konfig per-user KDE: systemowe domyślne przez environment.etc."xdg/..." + narzędzie kde-reset (czyści ~/.config). Nie wprowadzać zapisów wprost do home.
- Skrypty: fish, przez pkgs.writers.writeFishBin (bez ręcznego shebanga); w unitach systemd odwołania przez lib.getExe.
- Zewnętrzne narzędzia w skryptach tylko po ścieżkach ${pkgs.x}/bin/...
- Minimalne, celowe diffy — refaktoryzacja tylko, gdy jest częścią zadania.
