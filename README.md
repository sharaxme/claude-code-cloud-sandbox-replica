# claude-code-cloud-sandbox-replica

An unofficial, community-made Dockerfile that replicates the cloud sandbox
used by [Claude Code](https://code.claude.com), Anthropic's coding agent:
Ubuntu 24.04, the same CPU/RAM/disk resource envelope, and the same set of
pre-installed language toolchains (Python, Node.js, Java, Go, Rust, Ruby,
PHP, PostgreSQL, Redis, Docker CLI).

**This project is not affiliated with, endorsed by, or sponsored by
Anthropic.** "Claude" and "Anthropic" are used here only to describe, as a
matter of fact, what this image is a replica of. No Anthropic logo, brand
asset, or proprietary code is included. It is not a proxy, wrapper, or
client for Claude Code or any Anthropic product — it just gives you a
similarly-provisioned Ubuntu container for local development or testing.

## How this was built

Anthropic publishes the approximate resource ceiling for Claude Code cloud
sessions (4 vCPUs, 16 GB RAM, 30 GB disk) in its own docs:
<https://code.claude.com/docs/en/cloud-environments>.

The exact tool versions in this Dockerfile were captured by asking Claude
Code, inside one of its own cloud sessions, to run a set of standard
inventory commands — `cat /etc/os-release`, `uname -a`, `nproc`, `free -h`,
`df -h`, the built-in `check-tools` command, and version checks for each
toolchain (`python3 --version`, `node --version`, `java -version`, etc.) —
and reporting the output. That output (OS release, resource limits, and
installed tool versions) is not secret or proprietary; it's the same kind
of information any `docker inspect` or CI log would show for a sandboxed
build environment. Anything session-specific or credential-like (tokens,
session IDs, internal proxy addresses, CA bundle paths) was excluded before
publishing this repo.

## What's inside

| Category | Tools |
|---|---|
| OS | Ubuntu 24.04, x86_64 |
| Python | python3, pip, poetry, uv, black, mypy, pytest, ruff |
| Node.js | Node 22, npm, yarn, pnpm, eslint, prettier, corepack, ts-node, typescript, nodemon, playwright, chromedriver |
| Java | OpenJDK 21, Maven, Gradle |
| Go | go1.24 |
| Rust | rustc, cargo |
| Ruby | 3.3.x via rbenv |
| PHP | 8.4 (cli) + Composer |
| Databases | PostgreSQL 16, Redis 7 |
| Other | Docker CLI, Bun, git, jq, ripgrep, tmux |

Exact tool versions are pinned as of the inventory snapshot taken on
**2026-09-16** — check upstream release pages before assuming a pinned
version is still current.

## Build

```bash
docker build -t dev-sandbox-replica .
```

## Run

Resource limits roughly matching the original inspected environment
(4 vCPUs, ~15 GB RAM, no swap, ~30 GB writable disk quota):

```bash
docker run -it \
  --cpus=4 \
  --memory=15g \
  --memory-swap=15g \
  dev-sandbox-replica
```

To also cap writable disk usage (requires the `overlay2` storage driver on
an `xfs` backing filesystem — won't work on `ext4`):

```bash
docker run -it \
  --cpus=4 \
  --memory=15g \
  --memory-swap=15g \
  --storage-opt size=30G \
  dev-sandbox-replica
```

On a non-`xfs` host, use a size-limited volume instead of `--storage-opt`.

## Notes

- No credentials, tokens, or session-specific paths are included anywhere
  in this repository. If you inspect your own sandbox to extend this image,
  make sure to strip out anything similar before committing.
- Some install steps (Gradle, Go, rustup, rbenv, Bun, PHP PPA, NodeSource,
  Docker's install script) reach out to their respective upstream hosts
  during `docker build`. If a build step fails, the most likely cause is a
  moved download URL or a version that's been superseded — check the
  relevant project's release page and update the pinned version.
- This is a best-effort software-stack replica, not a hardware or
  virtualization replica. It won't reproduce host-level details like a
  specific kernel build or microVM isolation.

## Reproducing this yourself

To capture the same kind of inventory from your own Claude Code cloud
session (and check whether the versions in this Dockerfile are still
current), ask Claude Code to run:

```bash
echo "=== OS ==="
cat /etc/os-release
uname -a

echo "=== Resources ==="
nproc
free -h
df -h /

echo "=== check-tools (built-in) ==="
check-tools

echo "=== Package managers & versions ==="
python3 --version && pip3 --version
node --version && npm --version
ruby --version 2>/dev/null
php --version 2>/dev/null
java -version 2>&1
go version 2>/dev/null
rustc --version 2>/dev/null
psql --version 2>/dev/null
redis-server --version 2>/dev/null
docker --version 2>/dev/null

echo "=== Installed apt packages ==="
dpkg -l | wc -l
dpkg --get-selections > /tmp/apt-packages.txt

echo "=== Global npm packages ==="
npm list -g --depth=0

echo "=== Python packages ==="
pip3 list --format=freeze

echo "=== Environment variables ==="
env | sort
```

Before publishing your own output anywhere, strip anything that looks like
a credential — tokens (`GH_TOKEN`, `AWS_ACCESS_KEY_ID`, etc.), session IDs,
internal proxy ports, or CA bundle paths. None of that is needed to
reproduce the toolchain, and it's specific to your own session.

## Sources

- Claude Code cloud environment docs (resource limits, network policy):
  <https://code.claude.com/docs/en/cloud-environments>

## License

MIT — see [LICENSE](./LICENSE).
