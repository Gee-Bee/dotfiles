{ config, pkgs, ... }:

let
  thumbnailScript = pkgs.writeScript "preemptive-thumbnails-fish" ''
    #!${pkgs.fish}/bin/fish

    set DIRS "$HOME/Downloads" "$HOME/Pictures/Screenshots"

    # Szybka inicjalizacja katalogów bazowych
    for d in $DIRS; test -d $d; or mkdir -p $d; end

    # Monitorowanie zdarzeń I/O i natychmiastowe delegowanie zadań do silnika Plasma 6
    ${pkgs.inotify-tools}/bin/inotifywait -q -m -e close_write --format "%w%f" $DIRS | while read -l f
      if string match -r -i '\.(jpg|jpeg|png|webp|gif)$' "$f"
        qdbus org.freedesktop.thumbnails.Manager1 /org/freedesktop/thumbnails/Manager1 \
          Queue "file://$(path resolve $f)" "" "large" "default" 0 >/dev/null 2>&1
      end
    end
  '';
in
{
  systemd.user.services.preemptive-thumbnails = {
    description = "Pregenerowanie miniatur graficznych w tle dla Downloads i Screenshots";

    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${thumbnailScript}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
