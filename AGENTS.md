# AGENTS.md — zasady dla asystentów AI pracujących w tym repo

## Proces
- Zmiana podejścia to nowy punkt wyjścia: konfigurację lub kod wyprowadź od zera, a decyzje poprzedniego podejścia (zwłaszcza usunięcia) uzasadnij na nowo.
- Po zwinięciu dorywczej struktury (wydzielony plik, helper) wróć do pytania o jej zasadność — tymczasowe bywa wieczne.
- Eval/build dowodzi spójności, nie kompletności — po refactorze sprawdź end-to-end, że wynik nadal dostarcza to, co poprzednio (obecność pakietu, unitu, ścieżki).
- Przed pokazaniem przejrzyj kod raz pod kątem zasad sekcji Kod i sprawdź składnię (np. eval); testy i dłuższe buildy zostaw użytkownikowi.
- Minimalne, celowe diffy — refaktoryzacja tylko, gdy jest częścią zadania.
- Nie commituj i nie pushuj bez wyraźnej prośby — na koniec pokaż diff i czekaj na decyzję.
- Diagnostyka hosta: piaskownica agenta ma własne /etc — stan hosta sprawdzaj przez /.host-etc.

## Kod
- Czytelność ponad zwięzłość: nazwy opisowe, zero martwego kodu. Kod ma być zrozumiały bez komentarza.
- Najprostsze rozwiązanie spełniające zadanie: bez abstrakcji, opcji i zabezpieczeń na zapas.
- Duplikację tekstu zastąp zmienną lub funkcją pomocniczą; zła abstrakcja jest gorsza od duplikatu.
- Nie koduj ponad zadanie — dodatkowe usprawnienia zgłaszaj, nie wdrażaj.
- Nowy plik tylko, gdy przenosi realną odpowiedzialność; mikroplik z jedną funkcją zostaje w module macierzystym.
- Styl istniejącego pliku wygrywa z preferencjami; naruszenia powyższych zasad w dotykanym kodzie poprawiaj od razu, poza dotykanym kodem — tylko zgłoś.

## Komentarze
- Komentarz dotyczący konkretnej linii: na jej końcu lub tuż nad nią — nigdy przy nagłówku bloku; opcja i jej uzasadnienie zmieniają się razem.
- Komentarz uzasadnia decyzję (dlaczego tak), nie opisuje oczywistego "co robi kod".
- Każdy komentarz jest atomowy i samowystarczalny: czytelnik pliku nie zna historii git, diffów ani wcześniejszych rozmów. Zakaz fraz typu "bez zmian", "przywrócone", "tymczasowe", "wcześniej", "wg dyskusji".
- Zwięzłość: domyślnie 1 linia, maksymalnie 2. Jeśli treść się nie mieści — skróć do jednej decyzji, nie tłumacz mechanizmu. Komentarz tylko tam, gdzie kod sam się nie tłumaczy.
- Po angielsku.

## Nix / NixOS
- Flake w nixos/, bez Home Managera.
- Nieużywane argumenty modułów usuwaj; wartości użyte w więcej niż jednym miejscu trafiają do `let`.
- Nowy plik musi być śledzony przez git (wystarczy git add -N) — flake ignoruje nieśledzone pliki i eval pada.
- Konfig per-user KDE: systemowe domyślne przez environment.etc."xdg/..." + narzędzie kde-reset (czyści ~/.config). Nie wprowadzać zapisów wprost do home.
- Skrypty: fish, przez pkgs.writers.writeFishBin (bez ręcznego shebanga); w unitach systemd odwołania przez lib.getExe.
- Zewnętrzne narzędzia w skryptach tylko po ścieżkach ${pkgs.x}/bin/...; opcjonalne w działającym systemie wołaj przez /run/current-system/sw/bin po teście obecności.
