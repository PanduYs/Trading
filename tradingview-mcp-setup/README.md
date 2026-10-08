# Setup TradingView MCP untuk Claude

Menyambungkan Claude (Claude Code atau Claude Desktop) ke **TradingView Desktop** di komputer kamu lewat
[tradesdontlie/tradingview-mcp](https://github.com/tradesdontlie/tradingview-mcp).

Semua langkah dijalankan **di komputer kamu sendiri**, karena MCP ini mengendalikan aplikasi TradingView Desktop
lewat port debug lokal `127.0.0.1:9222`.

## Yang dibutuhkan

- TradingView **Desktop** (bukan versi browser) dengan akun aktif
- [Git](https://git-scm.com) dan [Node.js 18+](https://nodejs.org)
- Claude Code (CLI) dan/atau Claude Desktop

## 1. Install (otomatis)

Skrip di bawah ini meng-clone repo ke `~/tradingview-mcp`, menjalankan `npm install`, lalu mendaftarkan server
ke Claude Code (`claude mcp add -s user`) dan ke Claude Desktop. Kalau sudah ada server MCP lain, config-nya
**digabung** dan tidak ditimpa. Config lama Claude Desktop di-backup ke `.bak`.

**Windows** (PowerShell, dari folder ini):

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
```

**macOS / Linux:**

```bash
bash setup-mac-linux.sh
```

> Catatan: tutorial setra.id menyebut `~/.claude/.mcp.json` untuk Claude Code. Claude Code sebenarnya menyimpan
> server MCP level user di `~/.claude.json`, dan cara paling aman mengisinya adalah lewat `claude mcp add`.
> Itu yang dipakai skrip ini.

## 2. Jalankan TradingView mode debug

| OS | Perintah |
|----|----------|
| Windows | `%USERPROFILE%\tradingview-mcp\scripts\launch_tv_debug.bat` |
| macOS | `~/tradingview-mcp/scripts/launch_tv_debug_mac.sh` |
| Linux | `~/tradingview-mcp/scripts/launch_tv_debug_linux.sh` |

Skrip ini **menutup TradingView yang sedang terbuka**, lalu membukanya lagi dengan `--remote-debugging-port=9222`.

## 3. Restart Claude, lalu verifikasi

Tutup lalu buka lagi Claude Code / Claude Desktop, kemudian ketik:

```
Use tv_health_check to verify TradingView is connected
```

Kalau berhasil, `cdp_connected` bernilai `true`. Contoh prompt berikutnya:

```
Switch the chart to XAUUSD on 1-hour timeframe. Add EMA 200, EMA 50, and RSI 14.
Then tell me the current price and where RSI is right now.
```

## Kasus nyata: port 9222 dipakai Google Chrome (Windows)

Gejala: skrip launch menulis "CDP ready", tapi `tv_health_check` gagal dengan
`CDP connection failed ... Unexpected end of JSON input`.

Diagnosis:

```powershell
netstat -ano | findstr :9222                       # PID yang LISTENING
Get-Process -Id <PID> | Select ProcessName, Path   # ternyata chrome.exe
curl.exe -v http://127.0.0.1:9222/json/version     # 404 Not Found, body kosong
```

Skrip launch hanya mengecek exit code `curl`, jadi jawaban 404 dari Chrome tetap dianggap "CDP ready".

Solusi: pindahkan TradingView ke port lain (misalnya 9333).

1. Tambahkan `env` ke entry `tradingview` di config Claude Desktop:
   ```json
   "tradingview": {
     "command": "C:\\Program Files\\nodejs\\node.exe",
     "args": ["C:\\Users\\<USER>\\tradingview-mcp\\src\\server.js"],
     "env": { "TV_CDP_PORT": "9333" }
   }
   ```
2. Selalu buka TradingView dengan `scripts\launch_tv_debug.bat 9333`.
3. Verifikasi: `curl.exe -s http://127.0.0.1:9333/json/version` harus berisi `"Browser"` dan `TradingView/...`.

## Lokasi config Claude Desktop versi Microsoft Store

Kalau Claude Desktop dipasang dari Microsoft Store, `%APPDATA%\Claude\claude_desktop_config.json` tidak ada.
File aslinya ada di:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages\Claude_*\LocalCache\Roaming\Claude\claude_desktop_config.json"
```

Cara paling aman: Claude Desktop → Settings → Developer → Edit Config. Quit Claude Desktop sebelum menyimpan,
karena aplikasi juga menulis ke file ini. Cek validitas JSON sebelum membuka Claude lagi:

```powershell
Get-Content <path-config> -Raw | ConvertFrom-Json | Select -ExpandProperty mcpServers
```

Tes koneksi harus dilakukan di mode **Chat** Claude Desktop, bukan sesi Code di cloud.

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `cdp_connected: false` / `ECONNREFUSED` | TradingView belum jalan dalam mode debug. Ulangi langkah 2. |
| Windows: "Access is denied" | Minta Claude: *"Use tv_launch to start TradingView in debug mode"*. Tool ini menyalin aplikasi ke `%LOCALAPPDATA%` lalu menjalankannya dari sana. |
| Tool `tv_*` tidak muncul di Claude | Restart Claude. Cek dengan `claude mcp list` (harus ada `tradingview`). |
| `npm` / `node` tidak dikenali | Install Node.js 18+, lalu buka terminal baru. |

## Perlu diketahui

- Memakai API internal TradingView yang tidak didokumentasikan, jadi bisa rusak setelah TradingView di-update.
- README proyek aslinya mengakui penggunaan ini *mungkin* bertentangan dengan Terms of Use TradingView soal
  otomasi. Risikonya kamu tanggung sendiri.
- Port 9222 memberi kendali penuh atas aplikasi TradingView kepada program apa pun di komputer kamu. Tutup
  TradingView mode debug kalau tidak sedang dipakai.
