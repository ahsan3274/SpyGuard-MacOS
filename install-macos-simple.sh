#!/bin/bash
# SpyGuard macOS - Simple Setup Script
# No background services - just install and run manually when needed

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" ; pwd -P)"
SPYGUARD_DIR="/opt/spyguard"
VENV_DIR="/opt/spyguard/spyguard-venv"
CONFIG_DIR="/opt/spyguard/config"
LOG_DIR="/var/log/spyguard"
LOCALES=(en fr es ru pt de it pl)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

welcome_screen() {
cat << "EOF"
   __   _         __              _    _
  (_   |_)  \_/  /__  | |   /\   |_)  | \
  __)  |     |   \_|  |_|  /--\  | \  |_/

SpyGuard macOS - Simple Setup
No background services - run manually when needed
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
        echo -e "    ✓ macOS $MACOS_VERSION (Big Sur or later)"
    else
        echo -e "${YELLOW}    ⚠ macOS $MACOS_VERSION - May work but not tested${NC}"
    fi
}

check_homebrew() {
    echo -e "${GREEN}[+] Checking Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}    ⚠ Homebrew not installed${NC}"
        echo "    Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo -e "    ✓ Homebrew installed"
    fi

    if [[ "$ARCH_PREFIX" == "arm64" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
}

set_userlang() {
    echo -e "${GREEN}[+] Setting language...${NC}"
    printf -v joined '%s/' "${LOCALES[@]}"
    echo -n "    Choose language (${joined%/}): "
    read lang

    if [[ " ${LOCALES[@]} " =~ " ${lang} " ]]; then
        sed -i '' "s/userlang/${lang}/g" "${CONFIG_DIR}/config.yaml"
        echo -e "    ✓ Language set to: ${lang}"
    else
        echo -e "${RED}    ✗ Invalid language${NC}"
        set_userlang
    fi
}

set_credentials() {
    echo -e "${GREEN}[+] Setting backend credentials...${NC}"
    echo -n "    Backend username: "
    read username
    echo -n "    Backend password: "
    read -s password
    echo ""
    echo -n "    Confirm password: "
    read -s password_confirm
    echo ""

    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}    ✗ Passwords don't match${NC}"
        set_credentials
    else
        sed -i '' "s/userlogin/${username}/g" "${CONFIG_DIR}/config.yaml"
        sed -i '' "s/userpassword/${password}/g" "${CONFIG_DIR}/config.yaml"
        echo -e "    ✓ Credentials configured"
    fi
}

create_directories() {
    echo -e "${GREEN}[+] Creating directories...${NC}"
    sudo mkdir -p "${SPYGUARD_DIR}"
    sudo mkdir -p "${SPYGUARD_DIR}/database"
    sudo mkdir -p "${SPYGUARD_DIR}/config"
    sudo mkdir -p "${SPYGUARD_DIR}/assets"
    sudo mkdir -p "${LOG_DIR}/suricata"

    echo -e "    Copying files..."
    sudo cp -Rf "${SCRIPT_PATH}/analysis" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/server" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/app" "${SPYGUARD_DIR}/"
    sudo cp -Rf "${SCRIPT_PATH}/assets" "${SPYGUARD_DIR}/"
    sudo cp "${SCRIPT_PATH}/config.yaml" "${CONFIG_DIR}/"
    sudo cp "${SCRIPT_PATH}/watchers.yaml" "${SPYGUARD_DIR}/"
    sudo cp "${SCRIPT_PATH}/run-spyguard.sh" "${SPYGUARD_DIR}/"
    sudo chmod +x "${SPYGUARD_DIR}/run-spyguard.sh"

    echo -e "    ✓ Directories created"
}

install_packages() {
    echo -e "${GREEN}[+] Installing dependencies via Homebrew...${NC}"
    packages=("suricata" "wireshark" "sqlite" "openssl@3" "python@3.11" "dnsmasq")
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            echo -e "    ✓ ${package} already installed"
        else
            echo -e "    Installing ${package}..."
            brew install "$package" --quiet
        fi
    done
    echo -e "    ✓ Dependencies installed"
}

create_venv() {
    echo -e "${GREEN}[+] Creating Python virtual environment...${NC}"
    PYTHON3=$(brew --prefix python@3.11)/bin/python3.11
    sudo $PYTHON3 -m venv "${VENV_DIR}"

    echo -e "    Installing Python packages..."
    sudo "${VENV_DIR}/bin/pip3" install --upgrade pip --quiet
    sudo "${VENV_DIR}/bin/pip3" install -r "${SPYGUARD_DIR}/assets/requirements.txt" --quiet

    echo -e "    ✓ Virtual environment created"
}

generate_certificate() {
    echo -e "${GREEN}[+] Generating SSL certificate...${NC}"
    sudo openssl req -x509 \
        -subj '/CN=spyguard.local/O=SpyGuard Backend/C=US' \
        -newkey rsa:4096 -nodes \
        -keyout "${CONFIG_DIR}/key.pem" \
        -out "${CONFIG_DIR}/cert.pem" \
        -days 3650 \
        2>/dev/null

    echo -e "    ✓ SSL certificate generated"
}

create_database() {
    echo -e "${GREEN}[+] Creating SQLite database...${NC}"
    sqlite3 "${SPYGUARD_DIR}/database/database.sqlite3" < "${SPYGUARD_DIR}/assets/scheme.sql"
    sudo chown -R $(whoami):staff "${SPYGUARD_DIR}/database/"
    echo -e "    ✓ Database created"
}

fetch_iocs() {
    echo -e "${GREEN}[+] Fetching initial IOCs...${NC}"
    "${VENV_DIR}/bin/python3" "${SPYGUARD_DIR}/server/backend/watchers.py" 2>/dev/null || true
    echo -e "    ✓ IOCs fetched"
}

print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}How to use SpyGuard:${NC}"
    echo ""
    echo "1. Start SpyGuard:"
    echo -e "   ${GREEN}sudo ${SPYGUARD_DIR}/run-spyguard.sh${NC}"
    echo ""
    echo "2. Access the interfaces:"
    echo -e "   Frontend: ${GREEN}http://localhost:8000${NC}"
    echo -e "   Backend:  ${GREEN}https://localhost:8443${NC}"
    echo ""
    echo "3. Stop SpyGuard:"
    echo "   Press Ctrl+C in the terminal"
    echo ""
    echo -e "${YELLOW}Note: Internet Sharing must be enabled for network capture${NC}"
    echo "   System Settings → General → Sharing → Internet Sharing"
    echo ""
    echo -e "${BLUE}========================================${NC}"
}

# Main
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
    create_database
    fetch_iocs
    print_summary
}

main
