#!/usr/bin/env bash
# Setup tradingview-mcp di macOS / Linux.
# Usage: bash setup-mac-linux.sh [install_dir]
set -euo pipefail
INSTALL_DIR="${1:-$HOME/tradingview-mcp}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for cmd in git node npm; do
  command -v "$cmd" >/dev/null || { echo "$cmd belum terpasang. Install Git dan Node.js 18+ dulu."; exit 1; }
done
NODE_MAJOR="$(node --version | sed 's/^v//; s/\..*//')"
[ "$NODE_MAJOR" -ge 18 ] || { echo "Node.js 18+ dibutuhkan (terpasang: $(node --version))."; exit 1; }

echo "==> Clone / update tradingview-mcp ke $INSTALL_DIR"
if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only
else git clone https://github.com/tradesdontlie/tradingview-mcp.git "$INSTALL_DIR"; fi

echo "==> npm install"
(cd "$INSTALL_DIR" && npm install)
chmod +x "$INSTALL_DIR"/scripts/*.sh

echo "==> Daftarkan ke Claude Code"
if command -v claude >/dev/null; then
  claude mcp remove tradingview -s user >/dev/null 2>&1 || true
  claude mcp add tradingview -s user -- node "$INSTALL_DIR/src/server.js"
else
  echo "   Claude Code CLI tidak ditemukan, lewati."
fi

echo "==> Daftarkan ke Claude Desktop"
node "$SCRIPT_DIR/register-mcp.mjs" "$INSTALL_DIR"

if [ "$(uname)" = "Darwin" ]; then LAUNCH="$INSTALL_DIR/scripts/launch_tv_debug_mac.sh"
else LAUNCH="$INSTALL_DIR/scripts/launch_tv_debug_linux.sh"; fi

cat <<MSG

Selesai. Langkah berikut:
  1. Jalankan TradingView mode debug:  $LAUNCH
  2. Restart Claude Code / Claude Desktop
  3. Ketik ke Claude: Use tv_health_check to verify TradingView is connected
MSG
