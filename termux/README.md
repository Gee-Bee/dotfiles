# Termux Environment Setup

Minimalist, reproducible infrastructure on Google Pixel 3a managed via SSH from NixOS.

## Initial Phone Setup (Manual)

1. Install **Termux** and **Termux:Boot** from F-Droid:

   * [Termux on F-Droid](https://f-droid.org/en/packages/com.termux/)
   * [Termux:Boot on F-Droid](https://f-droid.org/en/packages/com.termux.boot/)

2. **Battery & Background Restrictions:** Go to Android system settings -> Apps -> Termux (and Termux:Boot) -> Battery, and set them to **Unrestricted** / **Not optimized**. This prevents Android from killing background services and containers.

3. Open Termux on the phone and run:

  ```bash
  pkg update && pkg install -y openssh rsync termux-services
  passwd
  sshd
  ```

## SSH Key Authentication (Passwordless)

Note your phone's IP address (e.g., via ifconfig or Wi-Fi settings) and username (whoami)

```bash
ssh-copy-id -i ~/.ssh/gmail_greg_bunia_ed25519.pub -p 8022 u0_a340@192.168.112.32
```

## Synchronization from Host (NixOS)

To sync all configuration files and scripts from your host machine (t530) to the phone, run the following rsync command from your laptop:

```bash
rsync -avz -e "ssh -p 8022" ./termux/ u0_a340@192.168.112.32:~/
ssh -p 8022 u0_a340@192.168.112.32 'chmod +x ~/.termux/boot/*.sh'
```

Note: Syncing the contents directly to ~/ maps files like termux/.bashrc straight to ~/.bashrc on the mobile device.

## Creating Services (Containers)

If you need a clean, ultra-lightweight container without extra packages, simply run:

```bash
create_container my_service
```

### Home Assistant

Since the `ha` container is dedicated exclusively to Home Assistant, packages are installed directly into the container's system (bypassing PEP 668 restrictions with `--break-system-packages`).

```bash
# Create the container with required system and build dependencies
create_container ha python3 python3-pip python3-full build-essential libssl-dev libffi-dev

# Configure global pip and install Home Assistant inside a single container session
proot-distro login ha -- bash << 'EOF'
mkdir -p /root/.config/pip
cat << 'CONF' > /root/.config/pip/pip.conf
[global]
break-system-packages = true
CONF

pip install --no-cache-dir homeassistant
EOF
```

start with
```bash
~/.termux/boot/10-start-ha.sh
```

The web interface will be available at http://192.168.112.32:8123