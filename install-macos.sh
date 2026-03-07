#!/bin/bash
# SpyGuard macOS Installation Script
# Native macOS port with Homebrew dependencies and LaunchDaemon services

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" ; pwd -P)"
LOCALES=(en fr es ru pt de it pl)
SPYGUARD_DIR="/opt/spyguard"
VENV_DIR="/opt/spyguard/spyguard-venv"
LAUNCHD_DIR="/Library/LaunchDaemons"
LOG_DIR="/var/log/spyguard"
CONFIG_DIR="/opt/spyguard/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

welcome_screen() {
cat << "EOF"
   __   _         __              _    _  
  (_   |_)  \_/  /__  | |   /\   |_)  | \ 
  __)  |     |   \_|  |_|  /--\  | \  |_/ 
                                  
SpyGuard macOS - Native Security Analysis Suite
A fork of TinyCheck (Kaspersky) with MISP integration
-----

EOF
}

check_architecture() {
    echo -e "${GREEN}[+] Checking system architecture...${NC}"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        echo -e "    ✓ Apple Silicon (M1/M2/M3) detected"
        export ARCH_PREFIX="arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        echo -e "    ✓ Intel Mac detected"
        export ARCH_PREFIX="x86_64"
    else
        echo -e "${RED}    ✗ Unsupported architecture: $ARCH${NC}"
        exit 1
    fi
}

check_macos_version() {
    echo -e "${GREEN}[+] Checking macOS version...${NC}"
    MACOS_VERSION=$(sw_vers -productVersion)
    MAJOR_VERSION=$(echo $MACOS_VERSION | cut -d. -f1)
    
    if [[ $MAJOR_VERSION -ge 11 ]]; then
        echo -e "    ✓ macOS $MACOS_VERSION (Big Sur or later) - Supported"
    else
        echo -e "${YELLOW}    ⚠ macOS $MACOS_VERSION - May work but not tested${NC}"
    fi
}

check_homebrew() {
    echo -e "${GREEN}[+] Checking Homebrew installation...${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}    ⚠ Homebrew not installed${NC}"
        echo -n "    Would you like to install Homebrew now? (y/n): "
        read install_brew
        if [[ "$install_brew" =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo -e "${RED}    ✗ Homebrew is required. Installation cancelled.${NC}"
            exit 1
        fi
    else
        echo -e "    ✓ Homebrew installed at $(which brew)"
    fi
    
    # Add Homebrew to PATH for Apple Silicon
    if [[ "$ARCH_PREFIX" == "arm64" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
}

set_userlang() {
    echo -e "${GREEN}[+] Setting the user language...${NC}"
    printf -v joined '%s/' "${LOCALES[@]}"
    echo -n "    Please choose a language (${joined%/}): "
    read lang

    if [[ " ${LOCALES[@]} " =~ " ${lang} " ]]; then
        sed -i '' "s/userlang/${lang}/g" "${CONFIG_DIR}/config.yaml"
        echo -e "${GREEN}    ✓ User language set to: ${lang}${NC}"
    else
        echo -e "${RED}    ✗ Invalid language. Please retry.${NC}"
        set_userlang
    fi
}

set_credentials() {
    echo -e "${GREEN}[+] Setting backend credentials...${NC}"
    echo -n "    Choose username for SpyGuard backend: "
    read login
    echo -n "    Choose password for SpyGuard backend: "
    read -s password1
    echo ""
    echo -n "    Confirm password: "
    read -s password2
    echo ""

    if [ "$password1" = "$password2" ]; then
        password=$(echo -n "$password1" | shasum -a 256 | cut -d" " -f1)
        sed -i '' "s/userlogin/${login}/g" "${CONFIG_DIR}/config.yaml"
        sed -i '' "s/userpassword/${password}/g" "${CONFIG_DIR}/config.yaml"
        echo -e "${GREEN}    ✓ Credentials saved successfully!${NC}"
    else
        echo -e "${RED}    ✗ Passwords don't match. Please retry.${NC}"
        set_credentials
    fi
}

create_directories() {
    echo -e "${GREEN}[+] Creating SpyGuard directories...${NC}"
    sudo mkdir -p "${SPYGUARD_DIR}"
    sudo mkdir -p "${LOG_DIR}"
    sudo mkdir -p "${CONFIG_DIR}"
    sudo mkdir -p "${SPYGUARD_DIR}/database"
    sudo mkdir -p "${SPYGUARD_DIR}/assets"
    
    # Copy project files
    echo -e "    Copying application files..."
    sudo cp -Rf "${SCRIPT_PATH}/analysis" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/server" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/app" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/assets" "${SPYGUARD_DIR}/"
    sudo cp "${SCRIPT_PATH}/config.yaml" "${CONFIG_DIR}/"
    sudo cp "${SCRIPT_PATH}/watchers.yaml" "${SPYGUARD_DIR}/"
    
    echo -e "${GREEN}    ✓ Directories created${NC}"
}

install_packages() {
    echo -e "${GREEN}[+] Installing system dependencies via Homebrew...${NC}"
    
    packages=("suricata" "wireshark" "sqlite" "openssl" "python@3.11" "dnsmasq")
    
    for package in "${packages[@]}"
    do
        if brew list "$package" &>/dev/null; then
            echo -e "${GREEN}    ✓ ${package} already installed${NC}"
        else
            echo -e "${YELLOW}    Installing ${package}...${NC}"
            brew install "$package" --quiet
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}    ✓ ${package} installed${NC}"
            else
                echo -e "${RED}    ✗ Failed to install ${package}${NC}"
            fi
        fi
    done
    
    # Link python@3.11
    brew link --overwrite python@3.11 2>/dev/null || true
}

create_venv() {
    echo -e "${GREEN}[+] Creating Python virtual environment...${NC}"
    
    # Use the installed Python 3.11
    PYTHON3=$(brew --prefix python@3.11)/bin/python3.11
    
    sudo $PYTHON3 -m venv "${VENV_DIR}"
    
    echo -e "    Installing Python packages..."
    sudo "${VENV_DIR}/bin/pip3" install --upgrade pip --quiet
    sudo "${VENV_DIR}/bin/pip3" install -r "${SPYGUARD_DIR}/assets/requirements.txt" --quiet
    
    echo -e "${GREEN}    ✓ Virtual environment created${NC}"
}

generate_certificate() {
    echo -e "${GREEN}[+] Generating SSL certificate for backend...${NC}"
    
    sudo openssl req -x509 \
        -subj '/CN=spyguard.local/O=SpyGuard Backend/C=US' \
        -newkey rsa:4096 -nodes \
        -keyout "${CONFIG_DIR}/key.pem" \
        -out "${CONFIG_DIR}/cert.pem" \
        -days 3650 \
        2>/dev/null
    
    echo -e "${GREEN}    ✓ SSL certificate generated${NC}"
}

create_launchdaemons() {
    echo -e "${GREEN}[+] Creating macOS LaunchDaemons...${NC}"
    
    # Frontend service
    sudo tee "${LAUNCHD_DIR}/com.spyguard.frontend.plist" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.spyguard.frontend</string>
    <key>ProgramArguments</key>
    <array>
        <string>${VENV_DIR}/bin/python3</string>
        <string>${SPYGUARD_DIR}/server/frontend/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${SPYGUARD_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/frontend.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/frontend.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

    # Backend service
    sudo tee "${LAUNCHD_DIR}/com.spyguard.backend.plist" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.spyguard.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>${VENV_DIR}/bin/python3</string>
        <string>${SPYGUARD_DIR}/server/backend/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${SPYGUARD_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/backend.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/backend.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
        <key>DYLD_LIBRARY_PATH</key>
        <string>/opt/homebrew/opt/openssl/lib</string>
    </dict>
</dict>
</plist>
EOF

    # Watchers service
    sudo tee "${LAUNCHD_DIR}/com.spyguard.watchers.plist" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.spyguard.watchers</string>
    <key>ProgramArguments</key>
    <array>
        <string>${VENV_DIR}/bin/python3</string>
        <string>${SPYGUARD_DIR}/server/backend/watchers.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${SPYGUARD_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/watchers.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/watchers.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
    <key>StartInterval</key>
    <integer>300</integer>
</dict>
</plist>
EOF

    # Set proper permissions
    sudo chown root:wheel "${LAUNCHD_DIR}/com.spyguard."*.plist
    sudo chmod 644 "${LAUNCHD_DIR}/com.spyguard."*.plist
    
    echo -e "${GREEN}    ✓ LaunchDaemons created${NC}"
}

load_launchdaemons() {
    echo -e "${GREEN}[+] Loading and starting LaunchDaemons...${NC}"
    
    # Unload if already loaded
    launchctl unload "${LAUNCHD_DIR}/com.spyguard.frontend.plist" 2>/dev/null || true
    launchctl unload "${LAUNCHD_DIR}/com.spyguard.backend.plist" 2>/dev/null || true
    launchctl unload "${LAUNCHD_DIR}/com.spyguard.watchers.plist" 2>/dev/null || true
    
    # Load services
    sudo launchctl load "${LAUNCHD_DIR}/com.spyguard.frontend.plist"
    sudo launchctl load "${LAUNCHD_DIR}/com.spyguard.backend.plist"
    sudo launchctl load "${LAUNCHD_DIR}/com.spyguard.watchers.plist"
    
    echo -e "${GREEN}    ✓ Services loaded and started${NC}"
}

create_suricata_config() {
    echo -e "${GREEN}[+] Configuring Suricata for macOS (PCAP mode)...${NC}"
    
    # Create Suricata config directory
    sudo mkdir -p /usr/local/etc/suricata
    
    # Generate Suricata config for macOS
    sudo tee "/usr/local/etc/suricata/suricata.yaml" > /dev/null <<EOF
%YAML 1.1
---

vars:
  address-groups:
    HOME_NET: "[10.0.0.0/8,172.16.0.0/12,192.168.0.0/16]"
    EXTERNAL_NET: "!$HOME_NET"
  port-groups:
    HTTP_PORTS: "80"
    SHELLCODE_PORTS: "!80"
    ORACLE_PORTS: "1521"
    SSH_PORTS: "22"

default-log-dir: ${LOG_DIR}/suricata/

stats:
  enabled: yes
  interval: 8

outputs:
  - fast:
      enabled: yes
      filename: fast.log
      append: yes
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert
        - http
        - dns
        - tls
        - files
        - ssh

logging:
  default-log-level: notice
  outputs:
    - console:
        enabled: yes
    - file:
        enabled: yes
        level: info
        filename: suricata.log

pcap:
  - interface: bridge100
    buffer-size: 16mb
    bpf-filter: "tcp or udp"
    checksum-checks: auto

default-rule-path: /opt/homebrew/share/suricata/rules

rule-files:
  - spyguard.rules

classification-file: /opt/homebrew/etc/suricata/classification.config
reference-config-file: /opt/homebrew/etc/suricata/reference.config
threshold-file: /opt/homebrew/etc/suricata/threshold.config
EOF

    # Create SpyGuard rules file
    sudo tee "/opt/homebrew/share/suricata/rules/spyguard.rules" > /dev/null <<EOF
# SpyGuard Custom Rules
# These rules complement the IOC-based detection

alert http any any -> any any (msg:"SPYGUARD Suspicious User-Agent"; flow:to_server,established; http_user_agent; content:"curl"; nocase; sid:1000001; rev:1;)
alert http any any -> any any (msg:"SPYGUARD Suspicious User-Agent"; flow:to_server,established; http_user_agent; content:"wget"; nocase; sid:1000002; rev:1;)
alert http any any -> any any (msg:"SPYGUARD Tor Exit Node Communication"; flow:to_server,established; content:"Host:"; http_header; pcre:"/Host:\s*[^\r\n]*\.onion/"; sid:1000003; rev:1;)
EOF

    # Create log directory
    sudo mkdir -p "${LOG_DIR}/suricata/"
    sudo chown -R $(whoami):staff "${LOG_DIR}/suricata/"
    
    echo -e "${GREEN}    ✓ Suricata configured for bridge100${NC}"
}

create_database() {
    echo -e "${GREEN}[+] Creating SQLite database...${NC}"
    
    sqlite3 "${SPYGUARD_DIR}/database/database.sqlite3" < "${SPYGUARD_DIR}/assets/scheme.sql"
    
    # Set proper permissions
    sudo chown -R $(whoami):staff "${SPYGUARD_DIR}/database/"
    
    echo -e "${GREEN}    ✓ Database created${NC}"
}

feeding_iocs() {
    echo -e "${GREEN}[+] Fetching initial IOCs and whitelist...${NC}"
    "${VENV_DIR}/bin/python3" "${SPYGUARD_DIR}/server/backend/watchers.py" 2>/dev/null || true
    echo -e "${GREEN}    ✓ IOCs fetched${NC}"
}

configure_firewall() {
    echo -e "${GREEN}[+] Configuring macOS firewall...${NC}"
    
    # Enable firewall (requires user approval in System Preferences)
    echo -e "${YELLOW}    Note: You may need to approve firewall changes in System Preferences${NC}"
    
    # Add rules for SpyGuard ports
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/spyguard/spyguard-venv/bin/python3 2>/dev/null || true
    
    echo -e "${GREEN}    ✓ Firewall configuration complete${NC}"
}

setup_permissions() {
    echo -e "${GREEN}[+] Setting up macOS permissions...${NC}"
    
    echo -e "${YELLOW}    IMPORTANT: SpyGuard requires the following permissions:${NC}"
    echo -e "    1. Full Disk Access (for packet capture)"
    echo -e "    2. Local Network Access (for device analysis)"
    echo -e ""
    echo -e "    Opening System Preferences..."
    
    # Open Security & Privacy preferences
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" 2>/dev/null || true
    
    echo -e "${YELLOW}    Please add Terminal (or your terminal app) to Full Disk Access${NC}"
    echo -e ""
    read -p "    Press Enter after granting permissions..."
    
    echo -e "${GREEN}    ✓ Permissions configured${NC}"
}

print_installation_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   SpyGuard macOS Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Frontend URL: ${GREEN}http://localhost:8000${NC}"
    echo -e "Backend URL:  ${GREEN}https://localhost:8443${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1. Configure Internet Sharing on your Mac:"
    echo "   - System Settings → General → Sharing → Internet Sharing"
    echo "   - Share your connection FROM: Wi-Fi/Ethernet"
    echo "   - TO computers using: Wi-Fi (creates bridge100)"
    echo ""
    echo "2. Connect the device you want to analyze to the SpyGuard network"
    echo ""
    echo "3. Access the frontend at http://localhost:8000"
    echo ""
    echo "4. Start a new capture and analysis session"
    echo ""
    echo -e "${YELLOW}Service Management:${NC}"
    echo "   Start:  sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.*.plist"
    echo "   Stop:   sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist"
    echo "   Status: launchctl list | grep spyguard"
    echo ""
    echo -e "${YELLOW}Logs:${NC}"
    echo "   ${LOG_DIR}/"
    echo ""
}

# Main installation flow
main() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root. Use: sudo bash $0${NC}"
        exit 1
    fi
    
    welcome_screen
    check_architecture
    check_macos_version
    check_homebrew
    create_directories
    set_userlang
    set_credentials
    install_packages
    create_venv
    generate_certificate
    create_suricata_config
    create_database
    create_launchdaemons
    load_launchdaemons
    feeding_iocs
    setup_permissions
    print_installation_summary
}

# Run main function
main
