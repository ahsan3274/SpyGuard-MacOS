# SpyGuard macOS - Native Security Analysis Suite

[![macOS](https://img.shields.io/badge/platform-macOS%2011+-blue)](https://support.apple.com/macos)
[![Python](https://img.shields.io/badge/python-3.11-green)](https://www.python.org)
[![License](https://img.shields.io/badge/license-Apache%202.0-orange)](LICENSE.txt)

> **Native macOS port of SpyGuard** with MISP Guard integration for advanced threat intelligence filtering.

## 🚀 Quick Start

### Installation

```bash
# Clone this repository
git clone https://github.com/ahsan3274/SpyGuard-MacOS.git
cd SpyGuard-MacOS

# Run macOS installer (requires password)
sudo bash install-macos.sh
```

> **Note:** The installer will prompt for your Mac password, language preference, and backend credentials. Installation takes 10-15 minutes.

### Or Use Existing Clone

If you already have the repository:

```bash
cd /path/to/SpyGuard  # Your existing clone
sudo bash install-macos.sh
```

### Access Interfaces

- **Frontend (Analysis):** http://localhost:8000
- **Backend (Management):** https://localhost:8443

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Installation** | Homebrew-based (automated) |
| **Services** | Manual runner script (simple) |
| **Network Capture** | PCAP/BPF via bridge100 |
| **Network Setup** | macOS Internet Sharing |
| **MISP Guard** | ✅ Compartment-based IOC filtering |

## 📖 Documentation

- **[macOS Installation Guide](README-macos.md)** - Complete setup instructions
- **[Internet Sharing Setup](docs/macos-internet-sharing-setup.md)** - Step-by-step network configuration
- **[Port Summary](MACOS_PORT_SUMMARY.md)** - Technical implementation details

## 🔍 Features

- 🔍 **IOC Detection** - Match traffic against threat intelligence
- 🧠 **Heuristic Analysis** - Detect suspicious behavior
- 🛡️ **MISP Integration** - Sync with MISP threat intelligence platforms
- 🎯 **MISP Guard Filtering** - Compartment-based IOC filtering
- 📊 **PDF Reports** - Detailed analysis reports
- 🌐 **Multi-language** - 8 languages supported

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│           SpyGuard macOS                     │
├──────────────────────────────────────────────┤
│  Frontend (Vue.js)  │  Backend (Flask)      │
│  Port 8000          │  Port 8443            │
├──────────────────────────────────────────────┤
│        Analysis Engine                       │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │ IOC      │ │Heuristics│ │MISP Guard  │  │
│  └──────────┘ └──────────┘ └────────────┘  │
├──────────────────────────────────────────────┤
│  Suricata (PCAP)  │  SQLite  │  Manual     │
│  bridge100        │  DB      │  Runner     │
└──────────────────────────────────────────────┘
```

## 🛠️ Requirements

- macOS Big Sur (11.0) or later
- Administrator privileges
- Homebrew (installed automatically)

## 📦 Components

### Installation Scripts
- `install-macos.sh` - macOS installer
- `uninstall-macos.sh` - Clean removal

### Platform Support
- `analysis/platform.py` - Linux/macOS abstraction layer

### MISP Guard Integration
- `server/backend/app/classes/misp_guard.py` - IOC filtering engine
- `server/backend/app/classes/misp_guard_config.json` - Filtering rules

### Documentation
- `README-macos.md` - Main macOS guide
- `docs/macos-internet-sharing-setup.md` - Network setup
- `MACOS_PORT_SUMMARY.md` - Implementation details

## 🔧 Service Management

### Manual Start/Stop (Recommended)

```bash
# Start SpyGuard
sudo /opt/spyguard/run-spyguard.sh

# Stop SpyGuard (press Ctrl+C in terminal)

# Check if running
lsof -i :8000 -i :8443
```

### Kill Stuck Processes

```bash
# Kill all SpyGuard processes
sudo pkill -9 -f spyguard

# Or kill by port
sudo lsof -ti :8000 -i :8443 | xargs sudo kill -9

# Wait for ports to release
sleep 5
```

## 📊 Logs

```bash
# View logs
tail -f /var/log/spyguard/frontend.log
tail -f /var/log/spyguard/backend.log
tail -f /var/log/spyguard/suricata/eve.json
```

## 🔒 macOS Permissions (TCC)

### Full Disk Access Required

SpyGuard requires **Full Disk Access** permission to capture network traffic on the `bridge100` interface. Without this permission, packet sniffing will fail silently.

#### Granting Full Disk Access

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Add your terminal application:
   - **Terminal.app**: `/Applications/Utilities/Terminal.app`
   - **iTerm2**: `/Applications/iTerm.app`
   - **VS Code Terminal**: `/Applications/Visual Studio Code.app`
4. Toggle Full Disk Access **ON** for your terminal
5. **Restart your terminal** for changes to take effect

#### Verifying Permissions

```bash
# Check if Full Disk Access is granted
tccutil reset All 2>/dev/null && echo "TCC access available" || echo "TCC access denied"
```

#### Troubleshooting

**Problem:** No traffic captured on bridge100

**Solution:**
1. Quit your terminal application completely
2. Re-open Terminal and run SpyGuard again
3. If still failing, try running from a different terminal app

**Problem:** "Operation not permitted" errors in logs

**Solution:**
1. Remove and re-add Full Disk Access permission
2. Ensure you're running the terminal with the granted permissions (not through Rosetta)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r assets/requirements.txt

# Run backend
cd server/backend && python3 main.py

# Run frontend (another terminal)
cd server/frontend && python3 main.py
```

## 📄 License

Apache License 2.0 - See [LICENSE.txt](LICENSE.txt) for details.

**Note:** IOC databases may have separate licenses (e.g., Creative Commons BY-NC-SA for ECHAP stalkerware IOCs).

## 🙏 Credits

- **Original:** TinyCheck by Kaspersky Lab
- **SpyGuard:** Felix Aimé
- **MISP Guard:** MISP Project
- **macOS Port:** SpyGuard Team
- **Development:** Created with [Qwen Code](https://github.com/QwenLM/Qwen) (Alibaba's AI Assistant)

## 📞 Support

- **Issues:** https://github.com/SpyGuard/SpyGuard/issues
- **Email:** spyguard@protonmail.com
- **Documentation:** See `docs/` directory

## 🏷️ Tags

`security` `macos` `threat-intelligence` `misp` `suricata` `network-analysis` `malware-detection` `stalkerware` `ioc` `cybersecurity`

Support the Project

If you find this fork useful, consider supporting its development: bc1qa25wm50g9pl26xzc0fl63reqxp47e05dp64942 (BTC)
