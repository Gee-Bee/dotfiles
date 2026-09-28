# Pixel 3a — Nix-on-Droid

The phone (Google Pixel 3a, aarch64) is managed declaratively with [Nix-on-Droid](https://github.com/nix-community/nix-on-droid). Configuration: this directory (`flake.nix` + `nix-on-droid.nix`). Home Assistant and dropbear come from the nixpkgs binary cache — no compilation on the phone (goodbye pip/cryptography).

## Nix-on-Droid install (one-off, manual)

1. Install **Nix-on-Droid** from F-Droid (`com.termux.nix`) — a Termux fork with nix built in; first launch downloads the bootstrap (hundreds of MB). Leave the phone alone after install — the first-start wizard's flake question is answered by the seeder below.
2. Android → Apps → Nix-on-Droid → Battery: **Unrestricted** (otherwise Android kills the services).
3. Seed and deploy — **`nod/deploy.sh --seed`** (USB debugging on, phone plugged into the laptop, **screen unlocked** — that unlock is the only human step):

```bash
nod/deploy.sh --seed
```

The script launches the app and types one base64 line into its shell over adb (`input text`; base64 carries no spaces or shell metacharacters, so it survives unquoted). The payload writes a minimal dropbear config into the app's private `$HOME` (no /sdcard) and switches; the script waits for dropbear, then rsyncs the flake and switches to it. The seed is typed repeatedly while the first-ever app launch is still downloading its bootstrap — the payload is idempotent.

Manual paste fallback (adb typing broken?): the script prints the same line when it gives up — paste it into the app's shell yourself, then rerun `nod/deploy.sh --seed`.

From the laptop (host firewall only blocks inbound — outgoing to the phone is fine):

```bash
rsync -avz --delete --exclude '.git' -e "ssh -p 8022" \
  ~/src/dotfiles/nod/ <u0_aNNN>@<phone-ip>:~/src/dotfiles/nod/
```

4. First switch — fetches ~150 MB from the cache (163 HA paths, zero compilation) and starts HA (activation writes a default `configuration.yaml`), dropbear (8022) and wake-lock. This is part of the seeded deploy; on an already-ssh-reachable phone it is just:

```bash
nix-on-droid switch --flake ~/src/dotfiles/nod
```

adb notes: `am startservice` RUN_COMMAND intents don't work here — the service is permission-gated, the `shell` user can't be granted the custom permission, and NOD lacks the `allow-external-apps` property anyway. Typing into the app goes through `monkey` (launch) + `input text` (payload), which need no permission beyond shell; the payload still travels base64-encoded and lands in the app's private `$HOME`.

## Deploying changes from the laptop

`nod/deploy.sh` does it all — discovers uid (owner of the app's `/data/data/com.termux.nix`) and ip (`ip addr`) over adb, rsyncs, switches:

```bash
nod/deploy.sh   # overrides: NOD_UID=u0_aNNN NOD_IP=a.b.c.d nod/deploy.sh
```

Equivalent by hand (uid changes on reinstall — `whoami` on the phone; ip drifts with DHCP; update the entry in `~/.ssh/config` on the laptop when it does):

```bash
rsync -avz --delete --exclude '.git' -e "ssh -p 8022" \
  ~/src/dotfiles/nod/ <u0_aNNN>@<phone-ip>:~/src/dotfiles/nod/
ssh -p 8022 <u0_aNNN>@<phone-ip> 'nix-on-droid switch --flake ~/src/dotfiles/nod'
```

`<phone-ip>` — DHCP drifts; read it from the laptop with `adb shell ip -4 addr show` (that's what deploy.sh does), or `ifconfig` on the phone.

On the t530, `nixos/modules/nix-on-droid.nix` defines a device-agnostic `nod` ssh alias instead of any `~/.ssh/config` entry: `adb forward tcp:8022 tcp:8022` maps the connected phone's 8022 onto localhost, so the alias survives DHCP drift and phone swaps — `ssh -l <u0_aNNN> nod`. Swapping the device (e.g. to an android-server box) changes nothing on the laptop: install Nix-on-Droid there and rerun `nod/deploy.sh --seed`.

## What starts on login

`build.activation.startServices` runs on every `nix-on-droid switch`/login:

- `termux-wake-lock` — holds the CPU (requires Unrestricted battery),
- HA with config in `~/.config/home-assistant` (persistent), UI: `http://<phone-ip>:8123`,
- dropbear on port 8022 with the laptop key (`~/.ssh/authorized_keys`, written from the config).

After a full phone reboot: open the Nix-on-Droid app once (that starts the session) — services come up from activation. The app also has the "run at startup" permission.

## Config changes

Edit `nix-on-droid.nix` → `nix-on-droid switch`. Rollback: `nix-on-droid rollback`. Generations and the store live on the phone; `nix-on-droid-collect-garbage` when space runs out.

## Later

TooGoodToGo: HA integration instead of standalone scripts — HACS with custom_components in `~/.config/home-assistant/custom_components/` (the directory is persistent in home).
