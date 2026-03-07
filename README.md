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

### Access Interfaces

- **Frontend (Analysis):** http://localhost:8000
- **Backend (Management):** https://localhost:8443

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Installation** | Homebrew-based (automated) |
| **Services** | launchd (auto-start on boot) |
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
│  Suricata (PCAP)  │  SQLite  │  launchd    │
│  bridge100        │  DB      │  Services   │
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

```bash
# Check status
launchctl list | grep spyguard

# Start services
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.*.plist

# Stop services
sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist
```

## 📊 Logs

```bash
# View logs
tail -f /var/log/spyguard/frontend.log
tail -f /var/log/spyguard/backend.log
tail -f /var/log/spyguard/suricata/eve.json
```

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
