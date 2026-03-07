# SpyGuard macOS - Simple Mode

**No background services. No launchd. No complexity.**

Just install, run when you need it, stop when done.

---

## Quick Start

### Installation

```bash
cd /Users/ahsan/Documents/GitHub/SpyGuard-MacOS
sudo bash install-macos-simple.sh
```

Takes 10-15 minutes. Installs dependencies and sets up everything.

---

### Running SpyGuard

```bash
sudo /opt/spyguard/run-spyguard.sh
```

That's it! You'll see:

```
========================================
Frontend: http://localhost:8000
Backend:  https://localhost:8443
========================================

Press Ctrl+C to stop all services
```

**Open your browser:** http://localhost:8000

---

### Stopping SpyGuard

Just press **Ctrl+C** in the terminal.

Done! Services stop immediately. No background processes.

---

## How It Works

```
You run: sudo run-spyguard.sh
         ↓
    Starts frontend (port 8000)
    Starts backend (port 8443)
         ↓
    Use the web interface
         ↓
    Press Ctrl+C
         ↓
    Everything stops
```

**No launchd, no plists, no auto-start, no background services.**

---

## Internet Sharing Setup

For network capture, enable Internet Sharing:

1. **System Settings** → **General** → **Sharing**
2. **Internet Sharing** → Click info (ⓘ)
3. Configure:
   - **Share FROM:** Wi-Fi or Ethernet
   - **To computers using:** Wi-Fi
4. Turn **Internet Sharing** ON

Connect the device you want to analyze to the SpyGuard network.

---

## Files

| File | Purpose |
|------|---------|
| `install-macos-simple.sh` | Simple installer (no services) |
| `run-spyguard.sh` | Manual runner script |
| `install-macos.sh` | Original installer (with launchd) |

---

## Comparison

### Simple Mode (This)

✅ No background services  
✅ Run only when needed  
✅ Easy to understand  
✅ Easy to debug  
✅ Full control  

**Best for:** Occasional use, testing, development

---

### Service Mode (Original)

✅ Auto-start on boot  
✅ Always running  
✅ No manual start needed  

**Best for:** Production, continuous monitoring

---

## Troubleshooting

### "Port already in use"

Something else is using port 8000 or 8443.

```bash
# Check what's using the ports
lsof -i :8000
lsof -i :8443

# Kill the process if needed
kill -9 <PID>
```

### "Virtual environment not found"

Run the installer again:

```bash
sudo bash install-macos-simple.sh
```

### "Config not found"

Make sure installation completed successfully. Check:

```bash
ls -la /opt/spyguard/config.yaml
```

---

## Default Credentials

Set during installation:
- **Username:** (you chose this)
- **Password:** (you chose this)

---

## Logs

While running, logs appear in the terminal.

For error logs:

```bash
tail -f /var/log/spyguard/frontend.error.log
tail -f /var/log/spyguard/backend.error.log
```

---

## Uninstall

```bash
sudo rm -rf /opt/spyguard
sudo rm -rf /var/log/spyguard
```

That's it! Everything removed.

---

## FAQ

**Q: Do I need to run this as sudo?**  
A: Yes, for network capture (packet sniffing).

**Q: Can I run without sudo?**  
A: No, Suricata needs raw socket access.

**Q: Does it auto-start?**  
A: No, that's the point! You run it manually.

**Q: Can I make it auto-start?**  
A: Use the original `install-macos.sh` instead (with launchd).

**Q: Which should I use?**  
A: 
- **Simple mode** (this) - for testing/occasional use
- **Service mode** (original) - for production/always-on

---

## Next Steps

1. **Install:** `sudo bash install-macos-simple.sh`
2. **Run:** `sudo /opt/spyguard/run-spyguard.sh`
3. **Access:** http://localhost:8000
4. **Analyze:** Connect device, start capture
5. **Stop:** Ctrl+C when done

---

**That's it! Simple as that.** 🎉
