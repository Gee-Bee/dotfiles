# TEMPFIX(drkonqi-6.7): delete this module and its import in configuration.nix when
# kdePackages.drkonqi reaches 6.7 (https://bugs.kde.org/show_bug.cgi?id=517353);
# for a 6.6.7 backport lower the gate instead. Drkonqi < 6.7 aborts on every launch
# ("Not exactly one fd passed by systemd"), so all its units get masked — dumps stay
# with systemd-coredump (coredumpctl).
{ pkgs, lib, ... }:

let
  drkonqiFixed = lib.versionAtLeast pkgs.kdePackages.drkonqi.version "6.7";
in
{
  systemd.user.services."drkonqi-coredump-pickup".enable = drkonqiFixed;
  systemd.user.services."drkonqi-coredump-launcher@".enable = drkonqiFixed;
  systemd.user.services."drkonqi-coredump-cleanup".enable = drkonqiFixed;
  systemd.user.services."drkonqi-sentry-postman".enable = drkonqiFixed;
  systemd.user.sockets."drkonqi-coredump-launcher".enable = drkonqiFixed;
  systemd.user.paths."drkonqi-sentry-postman".enable = drkonqiFixed;
  systemd.user.timers."drkonqi-sentry-postman".enable = drkonqiFixed;
  systemd.user.timers."drkonqi-coredump-cleanup".enable = drkonqiFixed;
  systemd.services."drkonqi-coredump-processor@".enable = drkonqiFixed;
}
