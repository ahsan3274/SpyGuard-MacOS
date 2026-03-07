#!/bin/bash
# SpyGuard macOS Uninstallation Script

set -e

SPYGUARD_DIR="/opt/spyguard"
LAUNCHD_DIR="/Library/LaunchDaemons"
LOG_DIR="/var/log/spyguard"
HOMEBREW_PREFIX=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   SpyGuard macOS Uninstaller${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check architecture for Homebrew prefix
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

# Stop services
echo -e "${YELLOW}[1/6] Stopping SpyGuard services...${NC}"
sudo launchctl unload -w "${LAUNCHD_DIR}/com.spyguard.frontend.plist" 2>/dev/null || true
sudo launchctl unload -w "${LAUNCHD_DIR}/com.spyguard.backend.plist" 2>/dev/null || true
sudo launchctl unload -w "${LAUNCHD_DIR}/com.spyguard.watchers.plist" 2>/dev/null || true
echo -e "${GREEN}      ✓ Services stopped${NC}"

# Remove LaunchDaemons
echo -e "${YELLOW}[2/6] Removing LaunchDaemons...${NC}"
sudo rm -f "${LAUNCHD_DIR}/com.spyguard."*.plist
echo -e "${GREEN}      ✓ LaunchDaemons removed${NC}"

# Remove application files
echo -e "${YELLOW}[3/6] Removing SpyGuard application files...${NC}"
sudo rm -rf "${SPYGUARD_DIR}"
echo -e "${GREEN}      ✓ Application files removed${NC}"

# Remove logs
echo -e "${YELLOW}[4/6] Removing log files...${NC}"
sudo rm -rf "${LOG_DIR}"
echo -e "${GREEN}      ✓ Log files removed${NC}"

# Remove Suricata rules
echo -e "${YELLOW}[5/6] Removing Suricata custom rules...${NC}"
sudo rm -f "${HOMEBREW_PREFIX}/share/suricata/rules/spyguard.rules" 2>/dev/null || true
echo -e "${GREEN}      ✓ Suricata rules removed${NC}"

# Ask about Homebrew packages
echo -e "${YELLOW}[6/6] Homebrew packages...${NC}"
echo -n "    Do you want to remove Homebrew packages (suricata, wireshark, etc.)? (y/n): "
read remove_packages

if [[ "$remove_packages" =~ ^[Yy]$ ]]; then
    echo -e "    Removing Homebrew packages..."
    brew remove suricata wireshark sqlite openssl@3 python@3.11 dnsmasq 2>/dev/null || true
    echo -e "${GREEN}      ✓ Homebrew packages removed${NC}"
else
    echo -e "    Keeping Homebrew packages"
fi

# Cleanup
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Uninstallation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Manual Steps Remaining:${NC}"
echo ""
echo "1. Disable Internet Sharing:"
echo "   System Settings → General → Sharing → Internet Sharing → OFF"
echo ""
echo "2. Remove firewall rules (if added):"
echo "   System Settings → Network → Firewall"
echo ""
echo "3. Remove Full Disk Access permission:"
echo "   System Settings → Privacy & Security → Full Disk Access"
echo ""
echo "4. Remove Local Network Access permission:"
echo "   System Settings → Privacy & Security → Local Network"
echo ""
echo -e "${YELLOW}Note: Your network settings and hostname have not been modified.${NC}"
echo ""
