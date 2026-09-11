create_container() {
    local name="$1"
    shift
    local packages="$@"
    [ -z "$name" ] && { echo "Error: Container name required." >&2; return 1; }

    # Ensure proot-distro is installed
    command -v proot-distro &>/dev/null || {
        echo "Installing proot-distro..."
        pkg install -y proot-distro
    }

    echo "Creating lightweight container: $name..."
    proot-distro install --override-alias "$name" debian:12 || {
        echo "Error: Failed to create container." >&2
        return 1
    }

    local rootfs="$PREFIX/var/lib/proot-distro/installed-rootfs/$name"

    # 1. Apply dpkg excludes to save space
    mkdir -p "$rootfs/etc/dpkg/dpkg.cfg.d"
    cat << 'EOF' > "$rootfs/etc/dpkg/dpkg.cfg.d/excludes"
path-exclude /usr/share/man/*
path-exclude /usr/share/doc/*
path-exclude /usr/share/locale/*
EOF

    # 2. Apply APT optimizations
    mkdir -p "$rootfs/etc/apt/apt.conf.d"
    cat << 'EOF' > "$rootfs/etc/apt/apt.conf.d/99optimization"
APT::Install-Recommends "0";
APT::Install-Suggests "0";
APT::Clean-Installed "true";
EOF

    # 3. Clean environment variables in profile
    cat << 'EOF' >> "$rootfs/etc/profile"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
unset TMPDIR TMP TEMP LD_LIBRARY_PATH
EOF

    # 4. Sync timezone if available on Android host
    [ -f /system/etc/localtime ] && cp /system/etc/localtime "$rootfs/etc/localtime"

    # 5. Install optional packages only if explicitly provided
    if [ -n "$packages" ]; then
        echo "Installing requested packages: $packages..."
        proot-distro login "$name" -- env DEBIAN_FRONTEND=noninteractive apt-get update
        proot-distro login "$name" -- env DEBIAN_FRONTEND=noninteractive apt-get install -y $packages
    fi

    echo "Container $name ready."
}
