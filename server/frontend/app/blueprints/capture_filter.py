#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import jsonify, Blueprint
import subprocess
import os

capture_filter_bp = Blueprint("capture_filter", __name__)

@capture_filter_bp.route("/filter/<token>/<target_ip>", methods=["POST"])
def api_capture_filter(token, target_ip):
    """ Filter capture to only include traffic from/to specific IP """
    try:
        capture_dir = f"/tmp/{token}"
        pcap_file = f"{capture_dir}/capture.pcap"
        filtered_pcap = f"{capture_dir}/capture_filtered.pcap"
        
        if not os.path.exists(pcap_file):
            return jsonify({"status": False, "message": "Capture file not found"})
        
        # Use tcpdump to filter PCAP by IP
        cmd = ["tcpdump", "-r", pcap_file, "-w", filtered_pcap, f"host {target_ip}"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Rename filtered file to replace original
            os.rename(filtered_pcap, pcap_file)
            return jsonify({"status": True, "message": f"Filtered for {target_ip}"})
        else:
            return jsonify({"status": False, "message": result.stderr})
            
    except Exception as e:
        return jsonify({"status": False, "message": str(e)})
