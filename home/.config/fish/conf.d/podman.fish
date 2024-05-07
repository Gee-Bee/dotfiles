if type -qs podman
  systemctl start --user podman.socket
  export DOCKER_HOST="unix:/$XDG_RUNTIME_DIR/podman/podman.sock"
end