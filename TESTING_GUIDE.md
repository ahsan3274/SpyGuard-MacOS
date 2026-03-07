# SpyGuard macOS Testing Guide

## Quick Test Steps

### Step 1: Run the Installer

Open Terminal and run:

```bash
cd /Users/ahsan/Documents/GitHub/SpyGuard-MacOS
sudo bash install-macos.sh
```

**Important:** The installer will prompt for:
1. Your Mac password (for sudo)
2. Language choice (en/fr/es/ru/pt/de/it/pl)
3. Backend username
4. Backend password (twice)

**Installation takes:** 10-15 minutes

---

### Step 2: Verify Installation

After installation completes, check:

```bash
# Check if directories were created
ls -la /opt/spyguard/

# Check if services are running
launchctl list | grep spyguard

# Check logs
ls -la /var/log/spyguard/
```

**Expected output:**
```
/opt/spyguard/
├── analysis/
├── app/
├── server/
├── database/
├── config/
└── assets/

com.spyguard.frontend
com.spyguard.backend
com.spyguard.watchers
```

---

### Step 3: Configure Internet Sharing

**Important:** SpyGuard needs Internet Sharing to create a network for device analysis.

1. **Open System Settings:**
   - Apple Menu () → System Settings

2. **Navigate to Sharing:**
   - General → Sharing

3. **Configure Internet Sharing:**
   - Click Info (ⓘ) next to "Internet Sharing"
   - **Share FROM:** Wi-Fi (or Ethernet)
   - **To computers using:** Wi-Fi
   - Click **Wi-Fi Options...**
   - **Network Name:** `SpyGuard-Test`
   - **Password:** Create a password
   - Click **OK**

4. **Enable Internet Sharing:**
   - Toggle Internet Sharing **ON**
   - Click **Start**

---

### Step 4: Grant Permissions

macOS requires explicit permissions:

1. **Full Disk Access:**
   - System Settings → Privacy & Security → Full Disk Access
   - Click **+** and add Terminal
   - Or enable for your terminal app

2. **Local Network Access:**
   - System Settings → Privacy & Security → Local Network
   - Enable for Terminal/Python

---

### Step 5: Access the Interface

**Frontend (User Interface):**
```bash
open http://localhost:8000
```

**Backend (Management):**
```bash
open https://localhost:8443
```

**Default credentials:** What you set during installation

---

### Step 6: Test Analysis

1. **Connect a device** to the `SpyGuard-Test` network
   - Use your phone or another device
   - Or use the same Mac on the shared network

2. **Open Frontend:** http://localhost:8000

3. **Start a capture session**

4. **Generate traffic:**
   - Browse websites on the connected device
   - Send messages
   - Use apps

5. **Wait 2-5 minutes** for traffic capture

6. **View results** and check for any detections

---

## Troubleshooting

### Services Not Starting

```bash
# Check service status
launchctl list | grep spyguard

# Restart services
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.*.plist
sudo launchctl load /Library/LaunchDaemons/com.spyguard.*.plist
```

### Can't Access Web Interface

```bash
# Check if ports are listening
lsof -i :8000
lsof -i :8443

# Check logs
tail -f /var/log/spyguard/frontend.log
tail -f /var/log/spyguard/backend.log
```

### No Traffic Captured

1. Verify Internet Sharing is ON
2. Check bridge interface:
   ```bash
   ifconfig bridge100
   ```
3. Ensure device is connected to SpyGuard network
4. Check Suricata logs:
   ```bash
   tail -f /var/log/spyguard/suricata/eve.json
   ```

### Permission Errors

```bash
# Grant Full Disk Access (manual)
# System Settings → Privacy & Security → Full Disk Access → Add Terminal

# Restart Terminal after granting
```

---

## Quick Commands Reference

| Action | Command |
|--------|---------|
| **Install** | `sudo bash install-macos.sh` |
| **Uninstall** | `sudo bash uninstall-macos.sh` |
| **Check services** | `launchctl list \| grep spyguard` |
| **Start services** | `sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.*.plist` |
| **Stop services** | `sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist` |
| **View logs** | `tail -f /var/log/spyguard/*.log` |
| **Frontend** | http://localhost:8000 |
| **Backend** | https://localhost:8443 |

---

## Expected Installation Output

```
   __   _         __              _    _  
  (_   |_)  \_/  /__  | |   /\   |_)  | \ 
  __)  |     |   \_|  |_|  /--\  | \  |_/  
                                  
SpyGuard macOS - Native Security Analysis Suite

[+] Checking system architecture...
    ✓ Apple Silicon (M1/M2/M3) detected
[+] Checking macOS version...
    ✓ macOS 14.x (Big Sur or later) - Supported
[+] Checking Homebrew installation...
    ✓ Homebrew installed at /opt/homebrew/bin/brew
[+] Creating SpyGuard directories...
    ✓ Directories created
[+] Setting the user language...
[+] Setting backend credentials...
    ✓ Credentials saved successfully!
[+] Installing system dependencies via Homebrew...
    ✓ suricata installed
    ✓ wireshark installed
    ...
[+] Creating Python virtual environment...
    ✓ Virtual environment created
[+] Generating SSL certificate for backend...
    ✓ SSL certificate generated
[+] Configuring Suricata for macOS (PCAP mode)...
    ✓ Suricata configured for bridge100
[+] Creating SQLite database...
    ✓ Database created
[+] Creating macOS LaunchDaemons...
    ✓ LaunchDaemons created
[+] Loading and starting LaunchDaemons...
    ✓ Services loaded and started
[+] Fetching initial IOCs and whitelist...
    ✓ IOCs fetched
[+] Setting up macOS permissions...
========================================
   SpyGuard macOS Installation Complete!
========================================

Frontend URL: http://localhost:8000
Backend URL:  https://localhost:8443
```

---

## Post-Installation Checklist

- [ ] Services running (`launchctl list | grep spyguard`)
- [ ] Frontend accessible (http://localhost:8000)
- [ ] Backend accessible (https://localhost:8443)
- [ ] Internet Sharing configured
- [ ] Permissions granted (Full Disk Access, Local Network)
- [ ] Can connect device to SpyGuard network
- [ ] Traffic appears in analysis
- [ ] PDF report generates

---

## Support

If you encounter issues:

1. Check logs: `/var/log/spyguard/`
2. Review guide: `docs/macos-internet-sharing-setup.md`
3. GitHub Issues: https://github.com/ahsan3274/SpyGuard-MacOS/issues
