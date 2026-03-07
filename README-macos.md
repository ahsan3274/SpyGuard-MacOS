# SpyGuard macOS - Native Security Analysis Suite

[![macOS](https://img.shields.io/badge/platform-macOS%2011+-blue)](https://support.apple.com/macos)
[![Python](https://img.shields.io/badge/python-3.11-green)](https://www.python.org)
[![License](https://img.shields.io/badge/license-Apache%202.0-orange)](LICENSE.txt)

> **⚠️ Amateur macOS port of SpyGuard** - Created with assistance from [Qwen Code](https://github.com/QwenLM/Qwen) (Alibaba's AI Assistant). This is a community port, not officially supported.

---

## 🚀 Quick Start

### Installation

```bash
# Clone this repository
cd /path/to/SpyGuard-MacOS

# Run installer (requires password)
sudo bash install-macos.sh
```

Installation takes 10-15 minutes. It will:
- Install Homebrew dependencies (Suricata, Wireshark, SQLite, Python 3.11)
- Create Python virtual environment
- Configure Suricata for macOS
- Generate SSL certificates
- Fetch initial IOCs

---

### Usage

#### 1. Enable Internet Sharing

SpyGuard uses macOS Internet Sharing to create a network for device analysis:

1. Open **System Settings** → **General** → **Sharing**
2. Select **Internet Sharing** (don't toggle yet)
3. Click the **Info button (ⓘ)**
4. Configure:
   - **Share FROM:** Wi-Fi or Ethernet (your active connection)
   - **To computers using:** Wi-Fi
5. Click **Wi-Fi Options...** and set network name (e.g., `SpyGuard-Analysis`)
6. Toggle **Internet Sharing** ON

#### 2. Start SpyGuard

```bash
sudo /opt/spyguard/run-spyguard.sh
```

#### 3. Access the Interface

- **Frontend:** http://localhost:8000
- **Backend:** https://localhost:8443

#### 4. Analyze a Device

1. Connect the device to your Mac's hotspot (the one you created in step 1)
2. Open the frontend at http://localhost:8000
3. **Set your phone's IP** (recommended: set static IP 192.168.2.2 on your phone)
4. Click **Start Capture**
5. Use your device normally for 15-30 minutes
6. Click **Stop Capture**
7. Click **Analyze Traffic**
8. View results!

---

## ✨ Features

| Feature | Status |
|---------|--------|
| **Installation** | ✅ Homebrew-based (automated) |
| **Services** | ✅ Manual runner script (simple) |
| **Network Capture** | ✅ PCAP/BPF via bridge100 |
| **Network Setup** | ✅ macOS Internet Sharing |
| **IOC Detection** | ✅ Suricata-based matching |
| **Heuristic Analysis** | ✅ Behavioral detection |
| **IP Filtering** | ✅ Filter by device IP |
| **PDF Reports** | ✅ WeasyPrint (auto-configured) |
| **Multi-language** | ✅ 8 languages supported |

---

## 📱 Finding Your Phone's IP

### Recommended: Set Static IP

**iPhone:**
1. Settings → Wi-Fi → Tap ⓘ next to hotspot
2. Configure IP → Manual
3. IP Address: `192.168.2.2`
4. Subnet: `255.255.255.0`
5. Router: `192.168.2.1`

**Android:**
1. Settings → Network → Wi-Fi → Tap network
2. Advanced → IP Settings → Static
3. IP Address: `192.168.2.2`
4. Gateway: `192.168.2.1`

### Or Find Current IP

**iPhone:** Settings → Wi-Fi → Tap ⓘ → See IP Address  
**Android:** Settings → Network → Wi-Fi → Tap network → Advanced → IP Address  
**Mac Terminal:** `arp -a` (look for 192.168.2.2 or .3)

---

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
│  │ IOC      │ │Heuristics│ │PDF Reports │  │
│  └──────────┘ └──────────┘ └────────────┘  │
├──────────────────────────────────────────────┤
│  Suricata (PCAP)  │  SQLite  │  Manual     │
│  bridge100        │  DB      │  Runner     │
└──────────────────────────────────────────────┘
```

---

## 🛠️ Requirements

- macOS Big Sur (11.0) or later
- Administrator privileges
- Homebrew (installed automatically)

---

## 📦 Components

### Installation & Scripts
- `install-macos.sh` - macOS installer
- `run-spyguard.sh` - Simple runner (no background services)
- `uninstall-macos.sh` - Clean removal

### Platform Support
- `analysis/platform.py` - Linux/macOS abstraction layer
- `analysis/utils.py` - Platform-aware paths
- `server/frontend/app/classes/capture.py` - macOS capture logic

### Documentation
- `README-macos.md` - This file (main guide)
- `docs/macos-internet-sharing-setup.md` - Network setup guide
- `docs/macos-services-architecture.md` - Service architecture

---

## 🔧 Service Management

### Manual Start/Stop (Recommended)

```bash
# Start
sudo /opt/spyguard/run-spyguard.sh

# Stop (Ctrl+C in terminal)

# Check status
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

---

## 📊 Logs

```bash
# View logs
tail -f /var/log/spyguard/frontend.log
tail -f /var/log/spyguard/backend.log
tail -f /var/log/spyguard/suricata/eve.json

# View errors
tail -f /var/log/spyguard/frontend.error.log
tail -f /var/log/spyguard/backend.error.log
```

---

## 🤝 Contributing

This is an **amateur port created with AI assistance**. Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
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

---

## 📄 License

Apache License 2.0 - See [LICENSE.txt](LICENSE.txt) for details.

**Note:** IOC databases may have separate licenses (e.g., Creative Commons BY-NC-SA for ECHAP stalkerware IOCs).

---

## 🙏 Credits & Acknowledgments

### Original Projects
- **TinyCheck** - Kaspersky Lab (original concept)
- **SpyGuard** - Felix Aimé (enhanced version)
- **MISP Guard** - MISP Project (IOC filtering)
- **CPI SpyGuard** - CyberPeace Institute (dependency updates)

### This macOS Port
- **Porting effort:** Amateur community port
- **Development assistance:** [Qwen Code](https://github.com/QwenLM/Qwen) (Alibaba's AI Assistant)
- **Not officially supported** by the original SpyGuard authors

### Technologies Used
- [Suricata](https://suricata.io/) - Network threat detection
- [Vue.js](https://vuejs.org/) - Frontend framework
- [Flask](https://flask.palletsprojects.com/) - Backend API
- [WeasyPrint](https://weasyprint.org/) - PDF generation
- [Homebrew](https://brew.sh/) - Package manager

---

## ⚠️ Known Limitations

### macOS Restrictions

1. **No Native Hotspot Creation**
   - Requires manual Internet Sharing setup
   - Cannot automate hotspot creation
   - User must configure in System Settings

2. **Packet Capture Permissions**
   - Requires running as root (sudo)
   - macOS security restrictions

3. **Network Interface Detection**
   - Uses `bridge100` (Internet Sharing bridge)
   - Different from Linux `wlan0`

### Platform Differences

| Feature | Linux | macOS |
|---------|-------|-------|
| Hotspot | Automatic (hostapd) | Manual (Internet Sharing) |
| Capture | AF_PACKET | PCAP/BPF |
| Service Manager | systemd | Manual runner |
| Package Manager | apt | Homebrew |
| Network Interface | wlan0 | bridge100 |

---

## 🐛 Troubleshooting

### Common Issues

#### No Traffic Captured
**Problem:** Analysis shows no network traffic

**Solution:**
1. Verify Internet Sharing is enabled
2. Check bridge interface: `ifconfig bridge100`
3. Ensure device is connected to SpyGuard network
4. Check Suricata config: `/opt/homebrew/etc/suricata/suricata.yaml`

#### Capture Stops with Error
**Problem:** "String did not match expected pattern"

**Solution:** This is a cosmetic error from Linux-specific code. The capture still works. Ignore the error and click "Analyze" anyway.

#### PDF Generation Failed
**Problem:** Analysis completes but no PDF report

**Solution:** 
```bash
# Install pango dependencies
brew install pango glib gdk-pixbuf librsvg

# Reinstall weasyprint
sudo /opt/spyguard/spyguard-venv/bin/pip install --force-reinstall weasyprint
```

#### Ports Stuck After Crash
**Problem:** "Address already in use"

**Solution:**
```bash
sudo lsof -ti :8000 -i :8443 | xargs sudo kill -9
sleep 5
sudo /opt/spyguard/run-spyguard.sh
```

---

## 📞 Support

This is an **unofficial community port**. For support:

- **Issues:** https://github.com/SpyGuard/SpyGuard/issues
- **Documentation:** See `docs/` directory
- **Original Project:** https://github.com/SpyGuard/SpyGuard

---

## 🏷️ Tags

`security` `macos` `threat-intelligence` `suricata` `network-analysis` `malware-detection` `stalkerware` `ioc` `cybersecurity` `amateur-port` `qwen-assisted`

---

**Last Updated:** March 2026  
**Version:** 1.0.0 (macOS Port - Amateur/Qwen-Assisted)  
**Status:** Functional with known limitations
