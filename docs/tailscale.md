# Tailscale

Tailscale puts the device on a private WireGuard network of your own. Once it
is joined, the WebUI and the APIs are reachable from your laptop or phone
wherever they are, with no port forwarding, no dynamic-DNS entry and nothing
exposed to the open internet.

HiFiBerryOS is Debian, so this is the ordinary Debian install — nothing about
it is HiFiBerry-specific except the notes at the end about what to reach once
it works.

## Install

Tailscale publishes its own apt repository. Add it, keyed to whatever Debian
release the image is built on, and install from it:

```bash
. /etc/os-release
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${VERSION_CODENAME}.noarmor.gpg" \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${VERSION_CODENAME}.tailscale-keyring.list" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update
sudo apt-get install -y tailscale
```

Reading the codename from `/etc/os-release` rather than typing it means the
same block works on a bookworm image and a trixie one. `arm64` and `armhf` are
both published, so this works on every Pi model HiFiBerryOS runs on.

Installing the package enables and starts `tailscaled`. The daemon is running
at this point but the device has not joined a network yet.

## Join the network

```bash
sudo tailscale up --accept-dns=false
```

The command prints a URL and then waits. Open the URL in a browser that is
logged in to your Tailscale account, approve the device, and the command
returns.

The device keeps whatever name it has on the LAN — a machine called `living-room`
appears in the tailnet as `living-room`. Add `--hostname=…` if you want a
different one there.

**Why `--accept-dns=false`:** with DNS accepted, Tailscale rewrites
`/etc/resolv.conf` to point at its own resolver. On an appliance that resolves
names for MPD, streaming services and the update check, that is a needless
extra dependency — if the tailnet resolver is unreachable the device stops
resolving anything. Leave it off unless you specifically want to reach other
tailnet machines by name *from* the device. Reaching the *device* by name from
elsewhere works either way.

### Without a browser on the device

There is nothing to install a browser for — `tailscale up` only prints a URL,
which you can open anywhere. But over a flaky SSH session, or when setting up
several devices, a pre-authentication key is easier. Generate one in the admin
console under **Settings → Keys**, then:

```bash
sudo tailscale up --accept-dns=false --authkey=tskey-auth-...
```

That returns immediately with nothing to approve. Treat the key like a
password: anyone holding it can add a machine to your network. Use a key that
expires, and prefer one marked single-use.

## Check it worked

```bash
tailscale status      # this device and every other machine on the network
tailscale ip -4       # this device's address, 100.x.y.z
```

`tailscale status` reporting `Logged out.` means the daemon is running but the
join never completed — run `tailscale up` again.

The address is stable and survives reboots; `tailscaled` is enabled, so the
device rejoins on its own after a power cut.

## Reaching the device

Everything that answers on the LAN answers on the Tailscale address too — it
is just another interface, and nothing in HiFiBerryOS binds to the LAN one
alone:

| | |
|---|---|
| WebUI | `http://100.x.y.z/` |
| AudioControl through nginx | `http://100.x.y.z/api/audiocontrol/...` |
| AudioControl direct | `http://100.x.y.z:1080/api/...` |
| SSH | `ssh <user>@100.x.y.z` |

With MagicDNS enabled on the network, the device's name works in place of the
address.

Two things worth setting in the admin console for a device meant to stay
reachable:

- **Disable key expiry** for it. Node keys expire after a few months by
  default, and a music player sitting in a rack is exactly the machine nobody
  notices has dropped off until they need it.
- Leave **Tailscale SSH** off unless you want it. It replaces the device's own
  SSH authentication with tailnet identity, which is a change to how the box is
  secured, not just how it is reached. Ordinary sshd with a key keeps working
  over the tunnel without it.

## Leaving, and removing

Disconnect but keep everything installed:

```bash
sudo tailscale down
```

Log out, so the device is no longer a member of the network:

```bash
sudo tailscale logout
```

Remove it completely:

```bash
sudo apt-get purge -y tailscale
sudo rm -f /etc/apt/sources.list.d/tailscale.list \
           /usr/share/keyrings/tailscale-archive-keyring.gpg
```

Deleting the machine in the admin console as well is what actually frees the
name; a purged device otherwise lingers there as an offline entry.

## Updates

Because the install came from Tailscale's apt repository, `apt upgrade` picks
up new versions with everything else. The repository is pinned to the Debian
release the image is on — after a distribution upgrade, rewrite
`/etc/apt/sources.list.d/tailscale.list` for the new codename by running the
two `curl` commands above again.
