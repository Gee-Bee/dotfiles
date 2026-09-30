# AGENTS.md — zasady dla asystentów AI pracujących w tym repo

## Proces
- Zmiana podejścia to nowy punkt wyjścia: konfigurację lub kod wyprowadź od zera, a decyzje poprzedniego podejścia (zwłaszcza usunięcia) uzasadnij na nowo.
- Kod zastany w drzewie roboczym to propozycja, nie zaakceptowana decyzja: jego podejście oceniaj od zera, zanim naprawisz, przebudujesz lub przetestujesz szczegóły.
- Po zwinięciu dorywczej struktury (wydzielony plik, helper) wróć do pytania o jej zasadność — tymczasowe bywa wieczne.
- Automatyzację rzadkiej procedury uzasadniaj porównaniem z jej wersją ręczną: gdy awaria mechanizmu boli bardziej niż jej ręczne wykonanie, proponuj usunięcie mechanizmu, nie jego naprawę.
- Eval/build dowodzi spójności, nie kompletności — po refactorze sprawdź end-to-end, że wynik nadal dostarcza to, co poprzednio (obecność pakietu, unitu, ścieżki).
- Jeśli najbardziej ryzykowna część zmiany jest nietestowalna w piaskownicy (integracja z żywym systemem), rekomendacja musi to nazywać i zawierać wariant rezygnacji; zielone światło obejmuje tylko to, co przetestowano.
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

## Dokumentacja
- Nowa linia w Markdown tylko tam, gdzie niesie strukturę (pusta linia, punktor, nagłówek, blok kodu, tabela) — akapit to jedna linia źródła; miękkie zawijanie zostaw edytorowi.
- Instrukcje i dokumentacja po angielsku, jak komentarze.

## Komentarze
- Komentarz dotyczący konkretnej linii: na jej końcu lub tuż nad nią — nigdy przy nagłówku bloku; opcja i jej uzasadnienie zmieniają się razem.
- Komentarz uzasadnia decyzję (dlaczego tak), nie opisuje oczywistego "co robi kod".
- Obejście odejmowalne po zewnętrznej zmianie (upgrade, backport, bugfix) oznaczaj `TEMPFIX(scope): <co usunąć i kiedy, z linkiem do buga/PR>` — grepowalne po upgradzie (`grep -rn TEMPFIX nixos/`); tam, gdzie to możliwe, kod sam wyłącza obejście (np. próg wersji w nix), a znacznik zostaje jako dokumentacja. Gdy obejście rozlewa się po wielu miejscach, izoluj je w osobnym pliku w `nixos/tempfix/` (nazwa pliku = scope znacznika; import w configuration.nix), by dało się je usunąć w całości. Test, czy obejście już zbędne: zakomentuj import, przebuduj i sprawdź efekt end-to-end — działa? kasujesz plik, nie działa? odkomentowujesz.
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
