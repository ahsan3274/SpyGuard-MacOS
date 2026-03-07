#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Platform abstraction layer for SpyGuard
Supports both Linux (original) and macOS (native port)
"""

import platform
import subprocess
import os
import re


class Platform:
    """Platform detection and utilities"""
    
    def __init__(self):
        self.system = platform.system()
        self.machine = platform.machine()
        self.release = platform.release()
        
        if self.system == "Darwin":
            self.is_macos = True
            self.is_linux = False
            self.os_name = "macOS"
            self.brew_prefix = self._get_brew_prefix()
        elif self.system == "Linux":
            self.is_macos = False
            self.is_linux = True
            self.os_name = "Linux"
            self.brew_prefix = None
        else:
            raise RuntimeError(f"Unsupported platform: {self.system}")
    
    def _get_brew_prefix(self):
        """Get Homebrew prefix path"""
        if self.is_macos:
            if self.machine == "arm64":
                return "/opt/homebrew"
            else:
                return "/usr/local"
        return None
    
    def get_python_path(self):
        """Get Python executable path"""
        if self.is_macos and self.brew_prefix:
            venv_paths = [
                "/opt/spyguard/spyguard-venv/bin/python3",
                f"{self.brew_prefix}/bin/python3.11",
                f"{self.brew_prefix}/bin/python3",
            ]
            for path in venv_paths:
                if os.path.exists(path):
                    return path
        return "/usr/bin/python3" if self.is_linux else "python3"
    
    def get_suricata_config_path(self):
        """Get Suricata configuration path"""
        if self.is_macos:
            return f"{self.brew_prefix}/etc/suricata/suricata.yaml" if self.brew_prefix else "/usr/local/etc/suricata/suricata.yaml"
        return "/etc/suricata/suricata.yaml"
    
    def get_suricata_rules_path(self):
        """Get Suricata rules path"""
        if self.is_macos:
            return f"{self.brew_prefix}/share/suricata/rules/" if self.brew_prefix else "/usr/local/share/suricata/rules/"
        return "/etc/suricata/rules/"
    
    def get_capture_interface(self):
        """Get the network capture interface name"""
        if self.is_macos:
            # macOS uses bridge100 for Internet Sharing
            return self._detect_bridge_interface() or "bridge100"
        else:
            # Linux uses wlan0 or similar
            return self._detect_linux_interface() or "wlan0"
    
    def _detect_bridge_interface(self):
        """Detect macOS bridge interface for Internet Sharing"""
        try:
            result = subprocess.run(
                ["ifconfig", "-l"],
                capture_output=True,
                text=True,
                timeout=5
            )
            interfaces = result.stdout.strip().split()
            for iface in interfaces:
                if iface.startswith("bridge"):
                    # Check if bridge has members (active)
                    bridge_result = subprocess.run(
                        ["ifconfig", iface],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if "member:" in bridge_result.stdout:
                        return iface
        except Exception:
            pass
        return None
    
    def _detect_linux_interface(self):
        """Detect Linux wireless interface"""
        try:
            # Try to find wireless interface
            for iface in os.listdir("/sys/class/net"):
                if iface.startswith("wl"):
                    return iface
        except Exception:
            pass
        return None
    
    def get_internet_check_url(self):
        """Get URL for internet connectivity check"""
        return "https://1.1.1.1"
    
    def is_internet_sharing_enabled(self):
        """Check if macOS Internet Sharing is enabled"""
        if not self.is_macos:
            return True  # Linux uses hostapd, different check
        
        try:
            # Check if bridge interface exists and has members
            result = subprocess.run(
                ["ifconfig", self.get_capture_interface()],
                capture_output=True,
                text=True,
                timeout=5
            )
            return "member:" in result.stdout or "inet " in result.stdout
        except Exception:
            return False
    
    def get_service_manager(self):
        """Get the service manager for the platform"""
        if self.is_macos:
            return "launchd"
        else:
            return "systemd"
    
    def restart_service(self, service_name):
        """Restart a service"""
        if self.is_macos:
            launchd_name = f"com.spyguard.{service_name}.plist"
            launchd_path = f"/Library/LaunchDaemons/{launchd_name}"
            try:
                subprocess.run(
                    ["sudo", "launchctl", "unload", launchd_path],
                    capture_output=True,
                    timeout=10
                )
                subprocess.run(
                    ["sudo", "launchctl", "load", launchd_path],
                    capture_output=True,
                    timeout=10
                )
                return True
            except Exception:
                return False
        else:
            try:
                subprocess.run(
                    ["sudo", "systemctl", "restart", f"spyguard-{service_name}"],
                    capture_output=True,
                    timeout=10
                )
                return True
            except Exception:
                return False
    
    def get_log_directory(self):
        """Get log directory path"""
        if self.is_macos:
            return "/var/log/spyguard"
        else:
            return "/var/log/spyguard"
    
    def get_data_directory(self):
        """Get data directory path"""
        if self.is_macos:
            return "/opt/spyguard"
        else:
            return "/usr/share/spyguard"
    
    def get_config_directory(self):
        """Get config directory path"""
        if self.is_macos:
            return "/opt/spyguard/config"
        else:
            return "/usr/share/spyguard"
    
    def get_temp_directory(self):
        """Get temp directory for captures"""
        return "/tmp"
    
    def can_create_hotspot(self):
        """Check if platform can create WiFi hotspot"""
        if self.is_macos:
            # macOS requires manual Internet Sharing setup
            return False
        else:
            # Linux can use hostapd
            return True
    
    def get_network_setup_instructions(self):
        """Get platform-specific network setup instructions"""
        if self.is_macos:
            return {
                "method": "internet_sharing",
                "steps": [
                    "Open System Settings → General → Sharing",
                    "Select 'Internet Sharing' (don't turn on yet)",
                    "Share your connection FROM: Wi-Fi or Ethernet",
                    "To computers using: Wi-Fi",
                    "Click 'Wi-Fi Options...' to configure network name",
                    "Turn on Internet Sharing",
                    "Connect the device to analyze to the SpyGuard network"
                ],
                "interface": "bridge100",
                "manual_setup": True
            }
        else:
            return {
                "method": "hostapd",
                "interface": "wlan0",
                "manual_setup": False
            }
    
    def get_pcap_capture_type(self):
        """Get the packet capture type for the platform"""
        if self.is_macos:
            return "pcap"  # macOS uses PCAP/BPF
        else:
            return "af_packet"  # Linux uses AF_PACKET
    
    def get_openssl_lib_path(self):
        """Get OpenSSL library path for the platform"""
        if self.is_macos and self.brew_prefix:
            return f"{self.brew_prefix}/opt/openssl/lib"
        return None


# Global platform instance
_current_platform = None


def get_platform():
    """Get the current platform instance"""
    global _current_platform
    if _current_platform is None:
        _current_platform = Platform()
    return _current_platform


def is_macos():
    """Check if running on macOS"""
    return get_platform().is_macos


def is_linux():
    """Check if running on Linux"""
    return get_platform().is_linux


# Backward compatibility - wrap old functions
def get_config(path):
    """Read config with platform-aware path resolution"""
    import yaml
    from functools import reduce
    
    platform_instance = get_platform()
    parent = platform_instance.get_data_directory()
    
    config = yaml.load(
        open(os.path.join(parent, "config.yaml"), "r"),
        Loader=yaml.SafeLoader
    )
    return reduce(dict.get, path, config)


def get_iocs(ioc_type):
    """Get IOCs with platform-aware database path"""
    import sqlite3
    
    platform_instance = get_platform()
    db_path = os.path.join(platform_instance.get_data_directory(), "database.sqlite3")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT value, tag FROM iocs WHERE type = ? ORDER BY value",
        (ioc_type,)
    )
    res = cursor.fetchall()
    conn.close()
    return [[r[0], r[1]] for r in res] if res is not None else []


def get_whitelist(elem_type):
    """Get whitelist with platform-aware database path"""
    import sqlite3
    
    platform_instance = get_platform()
    db_path = os.path.join(platform_instance.get_data_directory(), "database.sqlite3")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT element FROM whitelist WHERE type = ? ORDER BY element",
        (elem_type,)
    )
    res = cursor.fetchall()
    conn.close()
    return [r[0] for r in res] if res is not None else []
