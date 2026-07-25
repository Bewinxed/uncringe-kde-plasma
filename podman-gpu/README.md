# podman-gpu — containers with GPUs, without Docker Desktop

**The papercut:** every "Docker Desktop alternative" guide is written for macOS,
where the product's job is faking a Linux kernel. On Linux you already have one,
so the useful setup is different — rootless podman, `docker compose` pointed at
it, GPUs via CDI — and each piece has exactly one non-obvious step that fails
*silently*.

**The fix:** `podman-gpu install` does the whole thing. `podman-gpu doctor`
explains the failures that give you no usable error message.

```
podman-gpu install              # podman + compose + distrobox + NVIDIA CDI
podman-gpu check                # verify, incl. a real GPU container
podman-gpu doctor [compose.yml] # diagnose the silent failures
podman-gpu refresh              # regenerate the CDI spec after a driver change
podman-gpu box <name> [image]   # GPU distrobox with an isolated home
```

## The four things that fail silently

**1. `aardvark-dns` is only a *Recommends*.** Install podman with
`--no-install-recommends` — as most hardening guides tell you to — and you get a
podman with no container-name DNS. Every service that talks to another by name
dies with `getaddrinfo EAI_AGAIN mosquitto` and nothing anywhere mentions
aardvark. Worse, installing it later isn't enough: existing containers must be
**force-recreated** before they register.

**2. podman ignores `deploy.resources.reservations.devices`.** This is the GPU
syntax in every Docker Compose example on the internet. Under podman the
container starts happily with **no GPU and no error** — you only find out when
your detector or CUDA runtime falls over. The syntax podman honours is:

```yaml
services:
  whatever:
    devices: ["nvidia.com/gpu=all"]   # or nvidia.com/gpu=1 for a specific card
```

**3. `no-cgroups = true` is cargo cult.** Every rootless-GPU guide says to set
it. It belongs to the *legacy* nvidia runtime hook; with CDI, podman injects the
devices itself and `/dev/nvidia*` are already `0666`, so rootless works
untouched. Setting it is a system-wide change that breaks **rootful** GPU
containers in exchange for nothing. This installer deliberately does not.

**4. Rootless cannot write data that rootful Docker created.** Rootless podman
maps container root to *your* uid, so files owned by uid 0 are unwritable:

```
PermissionError: [Errno 13] Permission denied: '/config/.HA_VERSION'
sqlite3.OperationalError: attempt to write a readonly database
```

Note the filesystem angle: **NTFS mounted with `acl` stores real POSIX
ownership**, so `uid=` in fstab is only a fallback for files that lack it — a
drive shared with a previous Docker install keeps its uid-0 files. `doctor`
scans your bind mounts for exactly this.

## Rootless or rootful?

Rootless for dev work. **Rootful for a home-server stack** that declares
`privileged`, `network_mode: host`, `NET_ADMIN`, or mounts `/run/dbus` — those
do nothing real inside a user namespace, so Bluetooth and most system-bus
integrations quietly don't work. Home Assistant is the classic example.

They coexist; just remember the stores are **separate**. An `external: true`
network created rootless does not exist rootful, and vice versa:

```bash
sudo podman network create home_iot
sudo DOCKER_HOST=unix:///run/podman/podman.sock docker compose up -d
```

## CDI stays fresh by itself

The CDI spec hardcodes version-pinned driver paths (`libnvidia-ml.so.595.84`),
so a driver upgrade would break every GPU container. nvidia-container-toolkit
**≥ 1.19** ships `nvidia-cdi-refresh.{path,service}` watching
`/lib/modules/$(uname -r)/modules.dep`, which covers package upgrades *and*
hand-built drivers, since `make modules_install` rewrites `modules.dep`. Don't
hand-roll a unit of that name — you'll clobber NVIDIA's. On older toolkits, run
`podman-gpu refresh` after driver updates.

## distrobox boxes use `--nvidia`, not CDI

`podman-gpu box` creates boxes with distrobox's own `--nvidia`, which re-binds
the host driver stack at every start — so they survive driver upgrades with no
CDI regeneration at all. Don't combine the two mechanisms on one container or
the driver libraries land on the search path twice.

Each box gets `--home ~/.distrobox/<name>`. distrobox shares `$HOME` by default,
which means a container's `pip install --user` writes your real `~/.local` and
collides with the host and with every other box on a different CUDA version.
