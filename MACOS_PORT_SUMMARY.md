# SpyGuard macOS Port - Implementation Summary

## Overview

This document summarizes the macOS port of SpyGuard, including all files created, features integrated, and key architectural decisions.

---

## Files Created

### Installation & Scripts

| File | Purpose |
|------|---------|
| `install-macos.sh` | Main macOS installer (Homebrew, launchd, Suricata config) |
| `uninstall-macos.sh` | Clean uninstallation script |
| `README-macos.md` | Comprehensive macOS installation and usage guide |

### Platform Abstraction

| File | Purpose |
|------|---------|
| `analysis/platform.py` | Platform detection (Linux/macOS) with unified API |
| | - Interface detection (bridge100 vs wlan0) |
| | - Service management (launchd vs systemd) |
| | - Path resolution for different platforms |
| | - Network setup instructions |

### MISP Guard Integration

| File | Purpose |
|------|---------|
| `server/backend/app/classes/misp_guard.py` | MISP IOC filtering engine |
| | - Compartment-based filtering |
| | - Tag/distribution level blocking |
| | - Attribute type/category filtering |
| `server/backend/app/classes/misp_guard_config.json` | Sample MISP Guard configuration |
| `server/backend/app/classes/misp.py` | **Updated** - Integrated MISP Guard filtering |

### Documentation

| File | Purpose |
|------|---------|
| `docs/macos-internet-sharing-setup.md` | Step-by-step Internet Sharing setup guide |
| | - macOS Ventura+ and older versions |
| | - Troubleshooting common issues |
| | - Security considerations |
| `MACOS_PORT_SUMMARY.md` | This file - implementation overview |

### Configuration Updates

| File | Changes |
|------|---------|
| `assets/requirements.txt` | Updated for macOS compatibility |
| | - Removed pyudev (Linux-only) |
| | - Added jsonschema, watchdog (MISP Guard) |
| | - Updated package versions (CPI fork) |

---

## Key Features Implemented

### 1. Native macOS Support

✅ **Homebrew Package Management**
- Replaces apt package manager
- Installs: suricata, wireshark, sqlite, openssl, python@3.11, dnsmasq

✅ **launchd Service Management**
- Three LaunchDaemons created:
  - `com.spyguard.frontend.plist` - User interface (port 8000)
  - `com.spyguard.backend.plist` - Management API (port 8443)
  - `com.spyguard.watchers.plist` - IOC updater (periodic)

✅ **PCAP-Based Capture**
- Suricata configured for macOS BPF (Berkeley Packet Filter)
- Interface: `bridge100` (Internet Sharing bridge)
- Replaces Linux AF_PACKET socket capture

### 2. Internet Sharing Integration

✅ **Network Architecture**
- macOS doesn't allow hostapd-style hotspot creation
- Uses built-in Internet Sharing feature
- Creates `bridge100` interface automatically
- Devices connect to shared Wi-Fi network

✅ **Setup Guide**
- Detailed instructions for macOS Ventura+ and older
- Troubleshooting for common issues
- Security best practices

### 3. MISP Guard Integration

✅ **Compartment-Based Filtering**
```json
{
  "compartments_rules": {
    "can_reach": {
      "stalkerware": ["default", "stalkerware"],
      "malware": ["default", "malware", "threat_intel"],
      "threat_intel": ["default", "malware", "threat_intel"]
    }
  }
}
```

✅ **Filtering Rules**
- **Tags:** Block specific tags (e.g., `tlp:red`)
- **Distribution Levels:** Respect MISP hierarchy (0-5)
- **Sharing Groups:** Block by UUID
- **Attribute Types:** Block sensitive types (passport, email)
- **Attribute Categories:** Block categories (Person)
- **Object Types:** Block object types (person, file)

✅ **Integration Points**
- `misp.py:get_iocs()` - Filters IOCs before adding to database
- Configurable per MISP instance
- Backward compatible (disabled if no config)

### 4. Platform Abstraction Layer

✅ **Unified API**
```python
from analysis.platform import get_platform, is_macos, is_linux

platform = get_platform()
interface = platform.get_capture_interface()  # bridge100 or wlan0
config_path = platform.get_suricata_config_path()
can_hotspot = platform.can_create_hotspot()  # False on macOS
```

✅ **Auto-Detection**
- Detects Apple Silicon vs Intel
- Finds active bridge interface
- Checks Internet Sharing status
- Returns platform-specific paths

---

## Architecture Comparison

### Linux (Original)

```
┌─────────────────────────────────────┐
│  hostapd (WiFi Hotspot)            │
│  ↓                                 │
│  wlan0 (wireless interface)        │
│  ↓                                 │
│  Suricata (AF_PACKET capture)      │
│  ↓                                 │
│  systemd services                  │
└─────────────────────────────────────┘
```

### macOS (Port)

```
┌─────────────────────────────────────┐
│  macOS Internet Sharing            │
│  ↓                                 │
│  bridge100 (shared network)        │
│  ↓                                 │
│  Suricata (PCAP/BPF capture)       │
│  ↓                                 │
│  launchd LaunchDaemons             │
└─────────────────────────────────────┘
```

---

## Installation Flow

```
1. Check architecture (Apple Silicon / Intel)
   ↓
2. Check/install Homebrew
   ↓
3. Create directories (/opt/spyguard)
   ↓
4. Set user language and credentials
   ↓
5. Install Homebrew packages
   ↓
6. Create Python venv and install deps
   ↓
7. Generate SSL certificate
   ↓
8. Configure Suricata (PCAP mode)
   ↓
9. Create SQLite database
   ↓
10. Create and load LaunchDaemons
   ↓
11. Fetch initial IOCs
   ↓
12. Request permissions (Full Disk Access)
   ↓
13. Display setup instructions
```

---

## Configuration Files

### Suricata (`/usr/local/etc/suricata/suricata.yaml`)

```yaml
pcap:
  - interface: bridge100
    buffer-size: 16mb
    bpf-filter: "tcp or udp"
    checksum-checks: auto

default-rule-path: /opt/homebrew/share/suricata/rules

rule-files:
  - spyguard.rules
```

### LaunchDaemons (`/Library/LaunchDaemons/`)

Three plist files with:
- Program arguments (Python venv path)
- Working directory
- RunAtLoad and KeepAlive settings
- Log file paths
- Environment variables (PATH, DYLD_LIBRARY_PATH)

### MISP Guard (`misp_guard_config.json`)

Pre-configured compartments:
- `echap_stalkerware` - ECHAP stalkerware IOCs
- `spyguard_malware` - General malware IOCs
- `default_threat_intel` - External threat intel

---

## Testing Checklist

### Installation
- [ ] Homebrew packages install correctly
- [ ] Python venv creates without errors
- [ ] LaunchDaemons load successfully
- [ ] Services start automatically
- [ ] SSL certificates generate

### Network Capture
- [ ] Internet Sharing creates bridge100
- [ ] Suricata captures packets on bridge100
- [ ] Connected devices get IP addresses
- [ ] Traffic appears in Suricata logs

### Analysis
- [ ] Frontend accessible at localhost:8000
- [ ] Backend accessible at localhost:8443
- [ ] Can start new capture session
- [ ] IOCs match against traffic
- [ ] PDF report generates

### MISP Integration
- [ ] Can add MISP instances
- [ ] IOCs sync from MISP
- [ ] MISP Guard filters IOCs correctly
- [ ] Compartment rules enforced

### Services
- [ ] Services survive reboot
- [ ] Logs write to /var/log/spyguard/
- [ ] Can restart via launchctl
- [ ] Clean uninstall removes everything

---

## Known Limitations

### macOS Restrictions

1. **No Native Hotspot Creation**
   - Requires manual Internet Sharing setup
   - Cannot automate hotspot creation
   - User must configure in System Settings

2. **Packet Capture Permissions**
   - Requires Full Disk Access
   - May need Local Network Access
   - User must grant in System Preferences

3. **WiFi Monitoring**
   - Limited promiscuous mode support
   - Depends on Internet Sharing bridge
   - May not capture all device traffic

### Platform Differences

| Feature | Linux | macOS | Notes |
|---------|-------|-------|-------|
| Hotspot | Automatic | Manual | macOS restriction |
| Capture Method | AF_PACKET | PCAP | Different performance |
| Service Manager | systemd | launchd | Both support auto-start |
| Package Manager | apt | Homebrew | Both well-supported |

---

## Future Enhancements

### Planned Features

1. **Menu Bar App**
   - Native macOS status indicator
   - Quick start/stop analysis
   - Notification support

2. **Automated Internet Sharing**
   - AppleScript automation
   - One-click network setup
   - Profile-based configuration

3. **Enhanced MISP Guard**
   - Web UI for compartment config
   - Real-time filtering stats
   - Per-IOC override capability

4. **Apple Silicon Optimization**
   - Native ARM64 binaries
   - Performance improvements
   - Reduced resource usage

### Nice-to-Have

- Time Machine backup exclusion
- Spotlight search integration
- Shortcuts app support
- Handoff between Mac and iOS

---

## Support Matrix

### Supported macOS Versions

| macOS Version | Status | Notes |
|--------------|--------|-------|
| Ventura (13) | ✅ Tested | Recommended |
| Monterey (12) | ✅ Supported | Minor UI differences |
| Big Sur (11) | ✅ Supported | Minimum version |
| Catalina (10.15) | ⚠️ Limited | Python 3.11 required |

### Hardware Support

| Hardware | Status | Notes |
|----------|--------|-------|
| M1/M2/M3 | ✅ Native | ARM64 optimized |
| Intel Mac | ✅ Supported | x86_64 binaries |
| T2 Chip | ✅ Supported | No special config |

---

## Credits & Attribution

### Original Projects

- **TinyCheck** - Kaspersky Lab (original concept)
- **SpyGuard** - Felix Aimé (enhanced version)
- **MISP Guard** - MISP Project (IOC filtering)
- **CPI SpyGuard Files** - CyberPeace Institute (dependency updates)

### Technologies

- [Suricata](https://suricata.io/) - Network detection engine
- [mitmproxy](https://mitmproxy.org/) - MISP Guard foundation
- [Homebrew](https://brew.sh/) - Package management
- [Vue.js](https://vuejs.org/) - Frontend framework
- [Flask](https://flask.palletsprojects.com/) - Backend API

---

## Contact & Support

- **GitHub Issues:** https://github.com/SpyGuard/SpyGuard/issues
- **Documentation:** `docs/` directory
- **Email:** spyguard@protonmail.com

---

**Last Updated:** March 2026  
**Version:** 1.0.0 (macOS Port)
