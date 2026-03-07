# SpyGuard macOS - Internet Sharing Setup Guide

## Overview

SpyGuard on macOS uses **Internet Sharing** to create a network for device analysis. This is different from the Linux version which uses `hostapd`. macOS Internet Sharing creates a bridge interface (`bridge100`) that SpyGuard monitors for network traffic analysis.

## Prerequisites

- macOS Big Sur (11.0) or later
- Administrator privileges
- An active internet connection (Wi-Fi or Ethernet)

## Step-by-Step Setup

### Method 1: Using System Settings (Recommended)

#### For macOS Ventura (13.0) and Later

1. **Open System Settings**
   - Click Apple menu () → System Settings
   - Or press `Cmd + Space` and search for "System Settings"

2. **Navigate to Sharing**
   - Click on **General** in the sidebar
   - Click on **Sharing** on the right

3. **Configure Internet Sharing**
   - Find **Internet Sharing** in the list (don't toggle it yet)
   - Click the **Info button (ⓘ)** next to Internet Sharing

4. **Set Up Sharing**
   - **Share your connection FROM:** Select your active internet source
     - Wi-Fi (if connected via Wi-Fi)
     - Ethernet (if connected via cable)
     - USB Ethernet (if using USB adapter)
   
   - **To computers using:** Check **Wi-Fi**
   
5. **Configure Wi-Fi Network**
   - Click **Wi-Fi Options...**
   - **Network Name:** `SpyGuard-Analysis` (or your preferred name)
   - **Channel:** 11 (recommended)
   - **Security:** WPA2 Personal
   - **Password:** Create a strong password
   - Click **OK**

6. **Enable Internet Sharing**
   - Toggle **Internet Sharing** ON
   - Click **Start** in the confirmation dialog

#### For macOS Monterey (12.0) and Earlier

1. **Open System Preferences**
   - Click Apple menu () → System Preferences

2. **Navigate to Sharing**
   - Click on **Sharing**

3. **Configure Internet Sharing**
   - Select **Internet Sharing** in the left panel (don't check the box yet)
   
4. **Set Up Sharing**
   - **Share your connection FROM:** Select your active internet source
   - **To computers using:** Check **Wi-Fi**

5. **Configure Wi-Fi Network**
   - Click **Wi-Fi Options...**
   - Configure network name, channel, and password as above

6. **Enable Internet Sharing**
   - Check the box next to **Internet Sharing**
   - Click **Start** in the confirmation dialog

### Method 2: Using Command Line (Advanced)

For automated setups, you can use the `networksetup` command:

```bash
# Check current sharing status
sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.nat

# Enable NAT (required for Internet Sharing)
sudo sysctl -w net.inet.ip.forwarding=1

# Create bridge interface (if not automatically created)
sudo ifconfig bridge100 create

# Add interface to bridge (replace en0 with your Wi-Fi interface)
sudo ifconfig bridge100 addm en0

# Bring up the bridge
sudo ifconfig bridge100 up

# Configure bridge IP
sudo ifconfig bridge100 inet 192.168.2.1 netmask 255.255.255.0
```

## Verification

### Check if Internet Sharing is Active

```bash
# Check for bridge interface
ifconfig bridge100

# You should see output like:
# bridge100: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
#         ether aa:bb:cc:dd:ee:ff
#         inet 192.168.2.1 netmask 0xffffff00 broadcast 192.168.2.255
#         Configuration:
#             ap_mode
#         member: en0 id 00:00:00:00:00:00 priority 0 proto 0
```

### Check Network Connectivity

On the device you want to analyze:
1. Connect to the `SpyGuard-Analysis` network
2. Verify internet access works
3. Check that the IP address is in the 192.168.2.x range

## Troubleshooting

### Bridge Interface Not Found

**Problem:** `bridge100` doesn't exist

**Solution:**
```bash
# List all interfaces
ifconfig -l

# If no bridge exists, try toggling Internet Sharing off/on
# Or restart your Mac
```

### No Internet on Connected Devices

**Problem:** Devices connect but have no internet

**Solutions:**
1. Verify your Mac has active internet
2. Check that you're sharing FROM the correct interface
3. Try changing the Wi-Fi channel (1, 6, or 11 recommended)
4. Restart Internet Sharing

### SpyGuard Can't Capture Traffic

**Problem:** Analysis shows no network traffic

**Solutions:**
1. **Grant Full Disk Access:**
   - System Settings → Privacy & Security → Full Disk Access
   - Add Terminal (or your terminal app)
   - Restart Terminal

2. **Grant Local Network Access:**
   - System Settings → Privacy & Security → Local Network
   - Enable for Terminal/Python

3. **Check Suricata:**
   ```bash
   # Check Suricata logs
   tail -f /var/log/spyguard/suricata/eve.json
   
   # Restart Suricata
   sudo launchctl unload /Library/LaunchDaemons/com.spyguard.backend.plist
   sudo launchctl load /Library/LaunchDaemons/com.spyguard.backend.plist
   ```

### Internet Sharing Won't Enable

**Problem:** Internet Sharing toggle won't stay on

**Solutions:**
1. **Check Firewall:**
   - System Settings → Network → Firewall
   - Temporarily disable to test
   - Or add exceptions for SpyGuard

2. **Reset Network Settings:**
   ```bash
   # Remove network preferences (backup first!)
   sudo cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist ~/Desktop/
   sudo rm /Library/Preferences/SystemConfiguration/com.apple.nat.plist
   
   # Restart
   sudo reboot
   ```

## Security Considerations

### Network Security

- **Use WPA2/WPA3** encryption for the shared network
- **Change the default password** regularly
- **Disable Internet Sharing** when not in use

### Privacy

- Devices on the network can see network traffic
- Only analyze devices you own or have permission to test
- The analysis is for security purposes only

### Firewall Configuration

macOS Firewall may need configuration:

```bash
# Allow incoming connections for Python
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/spyguard/spyguard-venv/bin/python3

# Set to allow signed apps
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
```

## Best Practices

1. **Use in a controlled environment** - Public places, offices, or homes
2. **Limit analysis time** - 15-30 minutes is usually sufficient
3. **Interact with the device** during analysis to generate traffic
4. **Document findings** - Export reports for records
5. **Update IOCs regularly** - Run watchers for fresh threat intelligence

## Alternative: Ethernet Bridge

For devices without Wi-Fi or for more stable connections:

1. **Get a USB-to-Ethernet adapter**
2. **Share FROM Wi-Fi TO Ethernet**
3. **Connect device via Ethernet cable**
4. **Same analysis process applies**

## Uninstalling / Disabling

To disable Internet Sharing:

1. Open System Settings → General → Sharing
2. Toggle **Internet Sharing** OFF
3. Or uncheck in System Preferences (older macOS)

To completely remove SpyGuard:

```bash
# Stop services
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.*.plist

# Remove files
sudo rm -rf /opt/spyguard
sudo rm -rf /var/log/spyguard
sudo rm /Library/LaunchDaemons/com.spyguard.*.plist

# Restore network settings if needed
sudo reboot
```

## Support

For issues specific to macOS networking:
- Apple Support: https://support.apple.com
- SpyGuard Issues: https://github.com/SpyGuard/spyguard/issues

---

**Note:** This guide is for macOS native installation. Linux versions use `hostapd` for hotspot creation.
