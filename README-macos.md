# SpyGuard macOS - Native Security Analysis Suite

![macOS](https://img.shields.io/badge/platform-macOS%2011+-blue)
![Python](https://img.shields.io/badge/python-3.11-green)
![License](https://img.shields.io/badge/license-Apache%202.0-orange)

## Overview

SpyGuard for macOS is a **native port** of the SpyGuard network analysis tool, designed specifically for macOS. It detects signs of compromise on devices (smartphones, laptops, IoT) by monitoring their network traffic for Indicators of Compromise (IOCs), anomalies, and threats.

### Key Features

- 🔍 **IOC Detection** - Matches traffic against known threat intelligence
- 🧠 **Heuristic Analysis** - Detects suspicious behavior patterns
- 🛡️ **MISP Integration** - Syncs with MISP threat intelligence platforms
- 🎯 **Compartment Filtering** - MISP Guard integration for sensitive IOC filtering
- 📊 **PDF Reports** - Generates detailed analysis reports
- 🌐 **Multi-language** - Supports 8 languages (en, fr, es, ru, pt, de, it, pl)

### What's New in macOS Port

| Feature | Linux Version | macOS Port |
|---------|--------------|------------|
| **Installation** | apt packages | Homebrew |
| **Service Management** | systemd | launchd |
| **Network Capture** | AF_PACKET | PCAP/BPF |
| **Hotspot Creation** | hostapd | macOS Internet Sharing |
| **Interface** | wlan0 | bridge100 |
| **Python Dependencies** | Linux-specific | macOS-compatible (CPI fork) |
| **MISP Guard** | ❌ | ✅ **NEW** |

---

## Quick Start

### Prerequisites

- macOS Big Sur (11.0) or later
- Administrator privileges
- Homebrew installed (will be installed automatically if missing)

### Installation

```bash
# Clone the repository
cd /tmp && git clone https://github.com/SpyGuard/SpyGuard
cd SpyGuard

# Run the macOS installer
sudo bash install-macos.sh
```

The installer will:
1. Install dependencies via Homebrew (Suricata, Wireshark, SQLite, OpenSSL, Python 3.11)
2. Create Python virtual environment
3. Configure Suricata for macOS (PCAP mode)
4. Set up LaunchDaemons for background services
5. Generate SSL certificates
6. Fetch initial IOCs and whitelist
7. Request necessary permissions

### Post-Installation Setup

#### 1. Enable Internet Sharing

SpyGuard on macOS uses **Internet Sharing** to create a network for device analysis:

1. Open **System Settings** → **General** → **Sharing**
2. Select **Internet Sharing** (don't toggle yet)
3. Click the **Info button (ⓘ)**
4. Configure:
   - **Share FROM:** Wi-Fi or Ethernet (your active connection)
   - **To computers using:** Wi-Fi
5. Click **Wi-Fi Options...** and set network name (e.g., `SpyGuard-Analysis`)
6. Toggle **Internet Sharing** ON

📖 **Detailed guide:** See [docs/macos-internet-sharing-setup.md](docs/macos-internet-sharing-setup.md)

#### 2. Grant Permissions

macOS requires explicit permission for network capture:

1. **Full Disk Access:**
   - System Settings → Privacy & Security → Full Disk Access
   - Add your terminal application

2. **Local Network Access:**
   - System Settings → Privacy & Security → Local Network
   - Enable for Terminal/Python

#### 3. Access the Interface

- **Frontend (User Interface):** http://localhost:8000
- **Backend (Management):** https://localhost:8443

Default credentials are set during installation.

---

## Usage

### Analyzing a Device

1. **Connect the device** to the SpyGuard network (`SpyGuard-Analysis`)
2. **Open the frontend** at http://localhost:8000
3. **Start a new capture** session
4. **Interact with the device** (send messages, open apps, browse)
5. **Wait 15-30 minutes** for sufficient traffic capture
6. **View results** and export PDF report

### Best Practices

- ✅ Analyze in public places or controlled environments
- ✅ Interact with the device during analysis
- ✅ Update IOCs regularly via the backend
- ✅ Export reports for documentation

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SpyGuard macOS                           │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Vue.js)        │  Backend (Flask)               │
│  http://localhost:8000    │  https://localhost:8443        │
├─────────────────────────────────────────────────────────────┤
│                     Analysis Engine                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │
│  │ IOC Matching│  │  Heuristics │  │  MISP Guard     │    │
│  └─────────────┘  └─────────────┘  └─────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  Suricata (PCAP)  │  SQLite DB    │  LaunchDaemons         │
│  bridge100        │  IOCs/Config  │  Service Management    │
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
/opt/spyguard/
├── analysis/           # Core analysis engine
│   ├── classes/       # Engine, JARM, reports, MISP Guard
│   ├── locales/       # Language files
│   └── platform.py    # Platform abstraction (Linux/macOS)
├── server/
│   ├── backend/       # Management API (port 8443)
│   └── frontend/      # User interface API (port 8000)
├── app/
│   ├── backend/       # Vue.js admin interface
│   └── frontend/      # Vue.js user interface
├── database/          # SQLite database
├── config/            # Configuration files
└── logs/              # Service logs
```

---

## MISP Integration

### Connecting to MISP Instances

SpyGuard can sync IOCs from MISP threat intelligence platforms:

1. Access the **Backend** at https://localhost:8443
2. Navigate to **MISP Instances**
3. Add your MISP instance:
   - **Name:** Friendly name
   - **URL:** MISP instance URL
   - **API Key:** Your MISP API key
   - **SSL Verify:** Enable for production

### MISP Guard Filtering

The macOS port includes **MISP Guard** integration for advanced IOC filtering:

- **Compartment Rules:** Define which MISP instances can share IOCs
- **Tag Filtering:** Block IOCs with specific tags (e.g., `tlp:red`)
- **Distribution Levels:** Respect MISP distribution hierarchy
- **Attribute Filtering:** Block sensitive attribute types

Configuration: `server/backend/app/classes/misp_guard_config.json`

Example compartments:
- `stalkerware` - ECHAP stalkerware IOCs
- `malware` - General malware IOCs
- `threat_intel` - External threat intelligence

---

## Service Management

### Using launchctl

```bash
# Check service status
launchctl list | grep spyguard

# Start services
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.*.plist

# Stop services
sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist

# Restart a specific service
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.backend.plist
sudo launchctl load /Library/LaunchDaemons/com.spyguard.backend.plist
```

### Viewing Logs

```bash
# Frontend logs
tail -f /var/log/spyguard/frontend.log

# Backend logs
tail -f /var/log/spyguard/backend.log

# Suricata alerts
tail -f /var/log/spyguard/suricata/eve.json

# Watchers (IOC updates)
tail -f /var/log/spyguard/watchers.log
```

---

## Troubleshooting

### Common Issues

#### No Traffic Captured

**Problem:** Analysis shows no network traffic

**Solution:**
1. Verify Internet Sharing is enabled
2. Check bridge interface: `ifconfig bridge100`
3. Ensure device is connected to SpyGuard network
4. Grant Full Disk Access to Terminal

#### Services Won't Start

**Problem:** LaunchDaemons fail to load

**Solution:**
```bash
# Check plist syntax
plutil -lint /Library/LaunchDaemons/com.spyguard.*.plist

# Check logs
console.app → Search "spyguard"

# Reload services
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.*.plist
sudo launchctl load /Library/LaunchDaemons/com.spyguard.*.plist
```

#### Suricata Errors

**Problem:** Suricata fails to capture packets

**Solution:**
```bash
# Test Suricata config
suricata -T -c /usr/local/etc/suricata/suricata.yaml

# Check interface
ifconfig bridge100

# Restart backend
sudo launchctl restart com.spyguard.backend
```

### Getting Help

- **Documentation:** `docs/` directory
- **Issues:** https://github.com/SpyGuard/SpyGuard/issues
- **MISP Guard:** https://github.com/MISP/misp-guard

---

## Uninstallation

```bash
# Stop services
sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist

# Remove installation
sudo rm -rf /opt/spyguard
sudo rm -rf /var/log/spyguard
sudo rm /Library/LaunchDaemons/com.spyguard.*.plist

# Remove Homebrew packages (optional)
brew remove suricata wireshark sqlite openssl@3 python@3.11

# Disable Internet Sharing
# System Settings → General → Sharing → Internet Sharing → OFF
```

---

## Development

### Running from Source

```bash
# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r assets/requirements.txt

# Run backend
cd server/backend
python3 main.py

# Run frontend (in another terminal)
cd server/frontend
python3 main.py
```

### Building Vue.js Apps

```bash
# Backend app
cd app/backend
npm install
npm run build

# Frontend app
cd app/frontend
npm install
npm run build
```

---

## Security Considerations

- **Network Capture:** Requires elevated permissions
- **SSL Certificates:** Self-signed for local use only
- **IOC Data:** Handle according to TLP markings
- **Privacy:** Only analyze devices you own or have permission to test

---

## Credits

SpyGuard macOS is a fork and enhancement of:
- **TinyCheck** by Kaspersky Lab
- **SpyGuard** by Felix Aimé
- **MISP Guard** by MISP Project
- **CPI SpyGuard** by CyberPeace Institute

### Contributors

- Original concept: Kaspersky Lab
- SpyGuard enhancements: Felix Aimé, ECHAP
- macOS port: SpyGuard Team
- MISP Guard: MISP Project

### Technologies Used

- [Suricata](https://suricata.io/) - Network threat detection
- [Vue.js](https://vuejs.org/) - Frontend framework
- [Flask](https://flask.palletsprojects.com/) - Backend API
- [MISP](https://www.misp-project.org/) - Threat intelligence
- [Homebrew](https://brew.sh/) - Package manager
- [Wireshark](https://www.wireshark.org/) - Packet capture

---

## License

Apache License 2.0

**Note:** IOC databases may have separate licenses (e.g., Creative Commons BY-NC-SA for ECHAP stalkerware IOCs).

---

## Contact

- **Email:** spyguard@protonmail.com
- **Twitter:** @felixaime
- **Issues:** https://github.com/SpyGuard/SpyGuard/issues

---

## Changelog

### macOS Port (Current)

- ✅ Native macOS support (Intel + Apple Silicon)
- ✅ Homebrew-based installation
- ✅ launchd service management
- ✅ PCAP-based packet capture
- ✅ Internet Sharing integration
- ✅ MISP Guard filtering
- ✅ Updated Python dependencies (CPI fork)
- ✅ Platform abstraction layer

For original SpyGuard changelog, see the main repository.
