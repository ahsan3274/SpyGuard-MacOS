#!/bin/bash
# SpyGuard Watchers Launcher Script
# This script is called by launchd to start the watchers service

set -e

# Configuration
SPYGUARD_DIR="/opt/spyguard"
VENV_DIR="/opt/spyguard/spyguard-venv"
LOG_DIR="/var/log/spyguard"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Change to working directory
cd "$SPYGUARD_DIR"

# Activate virtual environment and run watchers
source "$VENV_DIR/bin/activate"
exec python3 "$SPYGUARD_DIR/server/backend/watchers.py"
