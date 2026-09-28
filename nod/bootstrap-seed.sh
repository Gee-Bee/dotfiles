# Bootstrap payload for the Pixel 3a (Nix-on-Droid). See README.md step 3.
#
# Written straight into the app's private $HOME by deploy.sh --seed (one line
# on the phone: `echo <base64>|base64 -d|sh`) — no /sdcard involved.
# The final `whoami` prints the u0_aNNN uid used by deploy.sh's rsync.
#
# Keep in sync with the manual-paste fallback block in README.md step 3.

mkdir -p ~/.config/nixpkgs
cat > ~/.config/nixpkgs/nix-on-droid.nix <<'EOF'
{ pkgs, ... }: {
  # no default in NOD; same value as the real config in nix-on-droid.nix
  system.stateVersion = "24.05";
  environment.packages = [ pkgs.dropbear ];
  build.activation.sshSeed = ''
    mkdir -p $HOME/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPOVgbvC6NCTBNeKJG650TEcb+6bbdzs1IyrwHyYg20 greg.bunia@gmail.com" > $HOME/.ssh/authorized_keys
    chmod 700 $HOME/.ssh; chmod 600 $HOME/.ssh/authorized_keys
  '';
  build.activation.dropbearSeed = ''
    ${pkgs.dropbear}/bin/dropbear -R -p 8022 &
  '';
}
EOF
nix-on-droid switch   # fetches only dropbear from the cache
whoami
