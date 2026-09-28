{ ... }:

{
  programs.ssh.extraConfig = ''
    # adb forward tcp:8022 tcp:8022 maps the device's 8022 onto localhost, so no
    # hostname/ip is baked in — the alias survives phone swaps (uid still drifts, pass it explicitly).
    Host nod
      HostName 127.0.0.1
      Port 8022
      # dropbear generates its host key at first boot and on app reinstall — nothing to pin
      StrictHostKeyChecking accept-new
  '';
}
