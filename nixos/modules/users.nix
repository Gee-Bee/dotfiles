{ config, pkgs, lib, primaryUser, ... }:

{
  # --- PROFILE UŻYTKOWNIKÓW & ZABEZPIECZENIA ---
  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.${primaryUser} = {
    isNormalUser = true;
    description = lib.toUpper primaryUser;
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "65535"; }
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];
}
