---
name: khadas-ops
description: "Khadas Edge 2 Pro ARM64 SSH operations — sudo pattern, PAM recovery warnings, apt repo ARM64 checks, Rust toolchain. Use when: 'ssh khadas', 'khadas@', '10.129.155.20', deploying to Khadas, ARM64 build, cargo build on Khadas, sudo on Khadas, apt on Khadas, pkexec, requiretty, or anything touching the Khadas box."
user-invocable: true
version: 1.0.0
context: root
---

# Khadas Edge 2 Pro — Operations Reference

Host: `khadas@10.129.155.20` | Arch: ARM64 (aarch64) | OS: Ubuntu 24.04
Auth: SSH key (ED25519), no password for SSH. Sudo password in macOS Keychain.
Build dir: `/home/khadas/seraph-src` | Deploy: `~/lightarchitects/seraph/bin/seraph`

## Rust toolchain gotcha

System cargo is 1.75 (too old). Rustup-managed cargo at `~/.cargo/env` is 1.93.1+.
Always `source ~/.cargo/env` before any cargo command.

```bash
ssh khadas@10.129.155.20 "source ~/.cargo/env && cd /home/khadas/seraph-src && cargo build --release"
```

## Sudo — standard pattern (requiretty fixed 2026-02-25)

`/etc/sudoers.d/khadas-notty` contains: `Defaults:khadas !requiretty`. Direct `sudo -S` now works.

```bash
KHADAS_SUDO=$(security find-generic-password -a "khadas" -s "khadas-sudo" -w)
ssh khadas@10.129.155.20 "echo '$KHADAS_SUDO' | sudo -S -p '' COMMAND"
```

## Sudo — recovery if requiretty comes back (e.g. after OS upgrade)

```bash
echo 'Defaults:khadas !requiretty' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/khadas-notty
sudo chmod 440 /etc/sudoers.d/khadas-notty
```

## DO NOT — PAM check footgun (learned 2026-02-25)

**Never** add `account required pam_exec.so` to `/etc/pam.d/sudo`. It caused complete sudo lockout:
- `pkexec` fails (polkit PAM auth broken)
- `su` root password locked/different
- Root SSH disabled (`PermitRootLogin no`)
- Only `khadas` user in sudo group

**Recovery required physical access** (HDMI+keyboard or serial):
```
nano /etc/pam.d/sudo           # remove the pam_exec line
rm -f /usr/local/bin/sudo-ssh-check.sh
```

Lesson: never add PAM account checks to sudo without a tested rollback + verified pkexec/su/root-SSH fallbacks.

## Credentials

| Credential | Location | Retrieval |
|------------|----------|-----------|
| SSH key | `~/.ssh/id_ed25519` (Mac) | auto (key-based auth) |
| Sudo password | macOS Keychain | `security find-generic-password -a "khadas" -s "khadas-sudo" -w` |
| Store sudo | — | `security add-generic-password -a "khadas" -s "khadas-sudo" -w "PASS"` |

## ARM64 package availability — check BEFORE adding repos

- **Zeek OBS repo** (`download.opensuse.org/repositories/security:/zeek/`) is amd64-only. No ARM64 builds. Use Suricata for IDS instead.
- Always verify ARM64 packages before adding a new apt repo:
  ```bash
  curl -s REPO_URL/Packages | grep -c "Architecture: arm64"
  ```

## APT install — one package at a time when mixing known/unknown

`apt-get install -y pkg1 pkg2` aborts ENTIRELY if either package is missing (rolls back already-resolved pkgs). Install separately:

```bash
sudo apt-get install -y pkg1 || true
sudo apt-get install -y pkg2 || true
```

## Sentinel (Echo) production build + deploy

```bash
# Sync source (Mac → Khadas):
rsync -av --exclude target --exclude .git \
  ~/Projects/Sentinel (Echo)/MCP/Sentinel (Echo)-DEV/ khadas@10.129.155.20:/home/khadas/seraph-src/

# Native ARM64 build:
ssh khadas@10.129.155.20 \
  "source ~/.cargo/env && cd /home/khadas/seraph-src && cargo build --release"

# Install:
ssh khadas@10.129.155.20 \
  "cp /home/khadas/seraph-src/target/release/seraph ~/lightarchitects/seraph/bin/seraph"
```

## Triggering this skill

This skill auto-triggers on: `khadas`, `ssh khadas`, `10.129.155.20`, `@khadas`, `ARM64`, `arm64`, `sudo on khadas`, `apt on khadas`, `pkexec`, `requiretty`, `seraph-src`, Sentinel (Echo) deployment to Khadas.

If the user mentions any Khadas-related operation, consult this skill first before suggesting commands.
