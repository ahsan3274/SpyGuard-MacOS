# SpyGuard macOS Service Architecture

## Overview

SpyGuard uses **launchd** (macOS service manager) with **shell script wrappers** for easier debugging and maintenance.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    launchd                              │
│  (macOS service manager - runs on system startup)      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ frontend.plist│ │ backend.plist │ │watchers.plist│
│ (config)      │ │ (config)      │ │ (config)     │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│start-frontend.│ │start-backend. │ │start-watchers│
│    sh         │ │    sh         │ │   .sh        │
│ (launcher)    │ │ (launcher)    │ │ (launcher)   │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│   python3     │ │   python3     │ │   python3     │
│   main.py     │ │   main.py     │ │   watchers.py │
│ (Flask app)   │ │ (Flask app)   │ │ (IOC sync)    │
└───────────────┘ └───────────────┘ └───────────────┘
```

---

## Why Shell Scripts Instead of Direct Python Calls?

### ✅ **Advantages of Shell Script Wrappers**

1. **Easier Debugging**
   - Can test manually: `bash start-frontend.sh`
   - Can add debug output, logging, error handling
   - Can check environment variables before running

2. **Cleaner Configuration**
   - All environment setup in one place
   - Virtual environment activation explicit
   - Easy to modify paths, add pre-checks

3. **Better Error Handling**
   - Can validate prerequisites before starting
   - Can create directories, check dependencies
   - Can provide meaningful error messages

4. **Flexibility**
   - Easy to add conditional logic
   - Can source different configs based on environment
   - Can run pre/post scripts

### ❌ **Direct Python in Plist (What We Changed From)**

```xml
<key>ProgramArguments</key>
<array>
    <string>/opt/spyguard/spyguard-venv/bin/python3</string>
    <string>/opt/spyguard/server/frontend/main.py</string>
</array>
```

**Problems:**
- Hard to debug (no shell output)
- Can't easily modify environment
- No pre-flight checks
- All config in plist or Python code

---

## File Structure

### LaunchDaemons (Plist Configuration)
Location: `/Library/LaunchDaemons/`

- `com.spyguard.frontend.plist` - Calls `start-frontend.sh`
- `com.spyguard.backend.plist` - Calls `start-backend.sh`
- `com.spyguard.watchers.plist` - Calls `start-watchers.sh`

### Launcher Scripts (Shell Wrappers)
Location: `/opt/spyguard/server/`

```
server/
├── frontend/
│   ├── main.py              # Flask application
│   └── start-frontend.sh    # Launcher script
└── backend/
    ├── main.py              # Flask application
    ├── watchers.py          # IOC sync script
    ├── start-backend.sh     # Backend launcher
    └── start-watchers.sh    # Watchers launcher
```

---

## Launcher Script Details

### Example: `start-frontend.sh`

```bash
#!/bin/bash
# SpyGuard Frontend Launcher Script

set -e

# Configuration
SPYGUARD_DIR="/opt/spyguard"
VENV_DIR="/opt/spyguard/spyguard-venv"
LOG_DIR="/var/log/spyguard"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Change to working directory
cd "$SPYGUARD_DIR"

# Activate virtual environment and run frontend
source "$VENV_DIR/bin/activate"
exec python3 "$SPYGUARD_DIR/server/frontend/main.py"
```

**Key Features:**
- `set -e` - Exit on any error
- `mkdir -p` - Ensure directories exist
- `cd` - Set working directory
- `source` - Activate Python virtual environment
- `exec` - Replace shell with Python (proper process management)

---

## Service Management

### Manual Testing (Debugging)

```bash
# Test frontend launcher
cd /opt/spyguard/server/frontend
bash start-frontend.sh

# Test backend launcher
cd /opt/spyguard/server/backend
bash start-backend.sh

# Test watchers launcher
cd /opt/spyguard/server/backend
bash start-watchers.sh
```

### launchd Control

```bash
# Start services
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.frontend.plist
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.backend.plist
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.watchers.plist

# Stop services
sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.*.plist

# Check status
launchctl list | grep spyguard

# Restart a service
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.frontend.plist
sudo launchctl load /Library/LaunchDaemons/com.spyguard.frontend.plist
```

### Viewing Logs

```bash
# Real-time log viewing
tail -f /var/log/spyguard/frontend.log
tail -f /var/log/spyguard/backend.log
tail -f /var/log/spyguard/watchers.log

# View errors
tail -f /var/log/spyguard/frontend.error.log
tail -f /var/log/spyguard/backend.error.log
```

---

## Plist Configuration Explained

### Example: `com.spyguard.frontend.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Service name -->
    <key>Label</key>
    <string>com.spyguard.frontend</string>
    
    <!-- What to run (shell script) -->
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/opt/spyguard/server/frontend/start-frontend.sh</string>
    </array>
    
    <!-- Where to run from -->
    <key>WorkingDirectory</key>
    <string>/opt/spyguard</string>
    
    <!-- Start on boot -->
    <key>RunAtLoad</key>
    <true/>
    
    <!-- Restart if crashed -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    
    <!-- Log files -->
    <key>StandardOutPath</key>
    <string>/var/log/spyguard/frontend.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/spyguard/frontend.error.log</string>
    
    <!-- Environment variables -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
```

### Key Plist Options

| Key | Purpose | Value |
|-----|---------|-------|
| `Label` | Service identifier | `com.spyguard.frontend` |
| `ProgramArguments` | Command to run | Array: `[bash, script.sh]` |
| `WorkingDirectory` | Where to run from | `/opt/spyguard` |
| `RunAtLoad` | Start on boot/load | `true` |
| `KeepAlive` | Restart policy | Dict with conditions |
| `StandardOutPath` | Stdout log file | Path |
| `StandardErrorPath` | Stderr log file | Path |
| `EnvironmentVariables` | Env vars for process | Dict |
| `StartInterval` | Run periodically (watchers) | Seconds (e.g., `300`) |

---

## Debugging Workflow

### 1. Test Script Manually

```bash
# Stop the service first
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.frontend.plist

# Run the script manually
cd /opt/spyguard/server/frontend
bash -x start-frontend.sh  # -x for debug output
```

### 2. Check Logs

```bash
# View launchd logs
log show --predicate 'process == "launchd"' --last 5m | grep spyguard

# View service logs
tail -100 /var/log/spyguard/frontend.error.log
```

### 3. Validate Plist Syntax

```bash
# Check plist syntax
plutil -lint /Library/LaunchDaemons/com.spyguard.frontend.plist

# Convert to JSON for easier reading
plutil -convert json -o - /Library/LaunchDaemons/com.spyguard.frontend.plist
```

### 4. Test launchd Load

```bash
# Load without -w (won't persist)
sudo launchctl load /Library/LaunchDaemons/com.spyguard.frontend.plist

# Check if running
launchctl list | grep spyguard

# Unload
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.frontend.plist
```

---

## Comparison: Shell Script vs Direct Python

| Aspect | Shell Script Wrapper | Direct Python in Plist |
|--------|---------------------|------------------------|
| **Debugging** | Easy - run manually | Hard - must use logs |
| **Environment Setup** | Flexible, explicit | Limited to plist env vars |
| **Error Messages** | Custom, clear | Python tracebacks only |
| **Pre-flight Checks** | Can validate first | No validation |
| **Maintenance** | Easier to modify | Must edit plist |
| **Complexity** | Slightly more files | Fewer files |
| **Performance** | Negligible overhead | Slightly faster start |
| **Best For** | Production, debugging | Simple services |

---

## Updating Services

### After Code Changes

```bash
# No need to reinstall! Just restart the service:
sudo launchctl unload /Library/LaunchDaemons/com.spyguard.frontend.plist
sudo launchctl load /Library/LaunchDaemons/com.spyguard.frontend.plist

# Or use the restart script:
bash fix-services.sh
```

### After Launcher Script Changes

```bash
# Same as above - just restart the service
# The plist loads the script fresh each time
```

### After Plist Changes

```bash
# Must unload and reload
sudo launchctl unload -w /Library/LaunchDaemons/com.spyguard.frontend.plist
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.frontend.plist
```

---

## Best Practices

### ✅ DO:

1. **Test scripts manually** before deploying to launchd
2. **Use `exec`** in scripts to replace shell with Python
3. **Set `set -e`** to exit on errors
4. **Create log directories** before writing
5. **Use absolute paths** in scripts and plists
6. **Validate plists** with `plutil -lint`
7. **Use `KeepAlive`** for auto-restart on crashes

### ❌ DON'T:

1. **Don't use `sudo`** inside launcher scripts (already root)
2. **Don't background the process** (launchd manages it)
3. **Don't use relative paths** (working directory may vary)
4. **Don't skip error handling** (use `set -e`)
5. **Don't modify plists while loaded** (unload first)

---

## Migration Notes

### From Direct Python to Shell Scripts

**Before (Direct Python):**
```xml
<key>ProgramArguments</key>
<array>
    <string>/opt/spyguard/spyguard-venv/bin/python3</string>
    <string>/opt/spyguard/server/frontend/main.py</string>
</array>
```

**After (Shell Script):**
```xml
<key>ProgramArguments</key>
<array>
    <string>/bin/bash</string>
    <string>/opt/spyguard/server/frontend/start-frontend.sh</string>
</array>
```

**Benefits:**
- Easier to debug issues
- Can add logging, validation
- Cleaner separation of concerns
- More maintainable

---

## Quick Reference

```bash
# Test a launcher script manually
bash /opt/spyguard/server/frontend/start-frontend.sh

# Validate a plist
plutil -lint /Library/LaunchDaemons/com.spyguard.frontend.plist

# Load all services
sudo launchctl load -w /Library/LaunchDaemons/com.spyguard.*.plist

# Check service status
launchctl list | grep spyguard

# View logs
tail -f /var/log/spyguard/frontend.log

# Restart all services
bash /path/to/SpyGuard-MacOS/fix-services.sh
```

---

**Last Updated:** March 2026  
**Version:** 1.1.0 (Shell Script Architecture)
