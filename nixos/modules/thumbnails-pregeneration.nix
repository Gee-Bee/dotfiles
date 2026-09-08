{ config, pkgs, ... }:

let
  thumbnailScript = pkgs.writeScript "preemptive-thumbnails-fish" ''
    #!${pkgs.fish}/bin/fish

    set DIRS "$HOME/Downloads" "$HOME/Pictures/Screenshots"
    mkdir -p $DIRS

    ${pkgs.inotify-tools}/bin/inotifywait -q -m -e close_write --format "%w%f" $DIRS | while read -l f
      string match -qr -i '\.(jpg|jpeg|png|webp|gif)$' "$f"; and \
        ${pkgs.kdePackages.qttools}/bin/qdbus org.freedesktop.thumbnails.Manager1 \
          /org/freedesktop/thumbnails/Manager1 Queue \
          "file://$(path resolve $f)" "" "large" "default" 0 >/dev/null 2>&1
    end
  '';
in
{
  systemd.user.services.preemptive-thumbnails = {
    description = "Pregenerate image thumbnails for Downloads and Screenshots";

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
