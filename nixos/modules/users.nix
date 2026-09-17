{ lib, primaryUser, ... }:

{
  # --- USER PROFILES & HARDENING ---
  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false; # single-user workstation, physical access required anyway

  users.users.${primaryUser} = {
    isNormalUser = true;
    description = lib.toUpper primaryUser;
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Raise fd/memlock limits for Electron apps, containers and media workloads
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "65535"; }
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];
}
