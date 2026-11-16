# OpenCode Native for Termux (No PRoot)

Run **OpenCode v2** natively on Android inside Termux without the lag, permission bugs, or `memfd_create` crashes of a PRoot container.

## Why this exists
If you try to run the official Linux ARM64 OpenCode binary directly in Termux, it breaks in a few annoying ways:
1. **Dynamic linker mismatch:** Android uses Bionic instead of glibc, so `opencode` (and its child `opencode serve` process) fails with `No such file or directory`.
2. **Termux `LD_PRELOAD` injection:** Termux injects `libtermux-exec-ld-preload.so` into every shell, which crashes glibc binaries with `version 'LIBC' not found`.
3. **GNU linker script conflict:** Termux's glibc ships `libc.so` as a plain-text linker script, causing `invalid ELF header` errors at runtime.
4. **Built-in updater overwrites patches:** Running `/update` or `opencode upgrade` replaces the binary with an unpatched Linux build.

This script fixes all four automatically and gives you a safe `opencode-update` command.

## Quick Install

Run this in normal Termux (not inside PRoot):

```bash
curl -fsSL https://githubusercontent.com | bash
source ~/.bashrc
```

Then `cd` into any project folder and run:

```bash
opencode
```

## Updating OpenCode

**Do not** use `/update` inside the TUI or `opencode upgrade`—that will download an unpatched binary and break your setup.

Instead, run:

```bash
opencode-update
```

It pulls the latest v2 release, re-applies `patchelf`, and keeps the `LD_PRELOAD=""` wrapper intact.

## Optional: Using Token Harbor Free Models

If you use [Token Harbor](https://tokenharbor.ai), you can hook up their free-tier models by creating `~/.config/opencode/opencode.json`:

```bash
mkdir -p ~/.config/opencode && cat << 'EOF' > ~/.config/opencode/opencode.json
{
  "\$schema": "https://opencode.ai",
  "provider": {
    "tokenharbor": {
      "name": "Token Harbor",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "https://tokenharbor.ai",
        "apiKey": "{env:TOKENHARBOR_API_KEY}"
      },
      "models": {
        "deepseek-v4.1-flash:free": { "name": "DeepSeek V4.1 Flash (Free)" },
        "deepseek-v4-flash:free": { "name": "DeepSeek V4 Flash (Free)" },
        "claude-haiku-5.5:free": { "name": "Claude Haiku 5.5 (Free)" },
        "mimo-v2.6-flash:free": { "name": "MiMo V2.6 Flash (Free)" },
        "mimo-v2.5:free": { "name": "MiMo V2.5 (Free)" },
        "kimi-k3:free": { "name": "Kimi K3 (Free)" }
      }
    }
  }
}
EOF
```

Make sure you activate the `:free` models on your Token Harbor dashboard, export your API key (`export TOKENHARBOR_API_KEY="thk_..."`), and select them with `/models` inside OpenCode.

## Credits
Built after debugging OpenCode v2.3+ child-process spawning and Bionic/glibc conflicts on Android Termux.
