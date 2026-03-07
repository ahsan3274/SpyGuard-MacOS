#!/bin/bash
# SpyGuard Backend Launcher Script
# This script is called by launchd to start the backend service

set -e

# Configuration
SPYGUARD_DIR="/opt/spyguard"
VENV_DIR="/opt/spyguard/spyguard-venv"
LOG_DIR="/var/log/spyguard"
OPENSSL_LIB="/opt/homebrew/opt/openssl/lib"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Change to working directory
cd "$SPYGUARD_DIR"

# Activate virtual environment and run backend
source "$VENV_DIR/bin/activate"
export DYLD_LIBRARY_PATH="$OPENSSL_LIB"
exec python3 "$SPYGUARD_DIR/server/backend/main.py"
