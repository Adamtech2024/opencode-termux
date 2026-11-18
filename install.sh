#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "=> Installing Termux dependencies..."
pkg update -y
pkg install -y curl tar patchelf resolv-conf glibc-repo
pkg update -y
pkg install -y glibc

# Fix glibc's plain-text libc.so linker script so dynamic loading doesn't fail
if [ -f "$PREFIX/glibc/lib/libc.so" ] && [ ! -L "$PREFIX/glibc/lib/libc.so" ]; then
    mv "$PREFIX/glibc/lib/libc.so" "$PREFIX/glibc/lib/libc.so.script"
    ln -sf "$PREFIX/glibc/lib/libc.so.6" "$PREFIX/glibc/lib/libc.so"
fi

echo "=> Downloading OpenCode v2..."
BASE_URL="https://opencode.ai"
INSTALL_PATH="/v2/install"
curl -fsSL "${BASE_URL}${INSTALL_PATH}" | bash -- --no-modify-path

INSTALL_DIR="$HOME/.opencode/bin"
mkdir -p "$INSTALL_DIR"

echo "=> Patching binary for Termux glibc..."
# Move raw binary if a wrapper already exists, otherwise use the freshly downloaded one
mv "$INSTALL_DIR/opencode" "$INSTALL_DIR/opencode.bin"

patchelf --set-interpreter "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" \
         --set-rpath "$PREFIX/glibc/lib" \
         "$INSTALL_DIR/opencode.bin"

echo "=> Creating LD_PRELOAD bypass wrapper..."
cat << 'EOF' > "$INSTALL_DIR/opencode"
#!/data/data/com.termux/files/usr/bin/bash
LD_PRELOAD="" exec "$HOME/.opencode/bin/opencode.bin" "$@"
EOF
chmod +x "$INSTALL_DIR/opencode"

echo "=> Creating safe opencode-update command..."
cat << 'EOF' > "$INSTALL_DIR/opencode-update"
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
U="https://opencode.ai"
P="/v2/install"
curl -fsSL "${U}${P}" | bash -s -- --no-modify-path
mv "$HOME/.opencode/bin/opencode" "$HOME/.opencode/bin/opencode.bin"
patchelf --set-interpreter "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" \
         --set-rpath "$PREFIX/glibc/lib" \
         "$HOME/.opencode/bin/opencode.bin"
cat << 'INNER' > "$HOME/.opencode/bin/opencode"
#!/data/data/com.termux/files/usr/bin/bash
LD_PRELOAD="" exec "$HOME/.opencode/bin/opencode.bin" "$@"
INNER
chmod +x "$HOME/.opencode/bin/opencode"
echo "OpenCode updated and patched!"
EOF
chmod +x "$INSTALL_DIR/opencode-update"

# Add to PATH cleanly if not already present
if ! grep -q '\.opencode/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ""
"$INSTALL_DIR/opencode" service set disabled true || true

echo "All done! Run these two commands to start:"
echo "  source ~/.bashrc"
echo "  opencode"
