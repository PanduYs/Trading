// Mendaftarkan server tradingview-mcp ke Claude Desktop (merge, tidak menimpa server lain).
// Usage: node register-mcp.mjs <path-ke-tradingview-mcp>
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const installDir = path.resolve(process.argv[2] || path.join(os.homedir(), 'tradingview-mcp'));
const serverJs = path.join(installDir, 'src', 'server.js');
if (!fs.existsSync(serverJs)) {
  console.error(`server.js tidak ditemukan di ${serverJs}`);
  process.exit(1);
}

function storeConfigPath() {
  // Claude Desktop versi Microsoft Store (MSIX) menyimpan config di folder paket.
  const pkgs = path.join(process.env.LOCALAPPDATA || '', 'Packages');
  if (!fs.existsSync(pkgs)) return null;
  const dir = fs.readdirSync(pkgs).find(d => d.startsWith('Claude_'));
  return dir ? path.join(pkgs, dir, 'LocalCache', 'Roaming', 'Claude', 'claude_desktop_config.json') : null;
}

const desktopConfig =
  (process.platform === 'win32' && storeConfigPath()) ||
  (process.platform === 'darwin'
    ? path.join(os.homedir(), 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json')
    : process.platform === 'win32'
      ? path.join(process.env.APPDATA || '', 'Claude', 'claude_desktop_config.json')
      : path.join(os.homedir(), '.config', 'Claude', 'claude_desktop_config.json'));

if (!fs.existsSync(path.dirname(desktopConfig))) {
  console.log('Claude Desktop tidak terdeteksi, lewati.');
  process.exit(0);
}

let config = {};
if (fs.existsSync(desktopConfig)) {
  const raw = fs.readFileSync(desktopConfig, 'utf8').trim();
  if (raw) {
    try {
      config = JSON.parse(raw);
    } catch (err) {
      console.error(`Config Claude Desktop tidak valid JSON (${desktopConfig}): ${err.message}`);
      process.exit(1);
    }
    fs.copyFileSync(desktopConfig, `${desktopConfig}.bak`);
  }
}

config.mcpServers = config.mcpServers || {};
config.mcpServers.tradingview = { command: process.execPath, args: [serverJs] };
if (process.env.TV_CDP_PORT) config.mcpServers.tradingview.env = { TV_CDP_PORT: process.env.TV_CDP_PORT };
fs.writeFileSync(desktopConfig, JSON.stringify(config, null, 2) + '\n');
console.log(`Claude Desktop: tradingview ditambahkan ke ${desktopConfig}`);
