#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from classes.engine import Engine
import sys
import json
import os

# Set library path for macOS (weasyprint needs pango, glib, etc.)
if sys.platform == 'darwin':
    brew_lib = '/opt/homebrew/lib'
    current = os.environ.get('DYLD_LIBRARY_PATH', '')
    if brew_lib not in current:
        os.environ['DYLD_LIBRARY_PATH'] = brew_lib + ':' + current if current else brew_lib

# PDF report generation is optional (requires weasyprint with pango)
try:
    from classes.report import Report
    HAS_PDF_SUPPORT = True
except ImportError as e:
    HAS_PDF_SUPPORT = False
    print(f"⚠️  PDF report generation disabled: {e}")

"""
    This file is called by the frontend to do the analysis.
"""

def analyze(capture_folder):
    """This method analyse a pcap. It:
        1. Launches the detection engine which uses suricata;
        2. Save the results inside the "assets" subfolder of the capture folder;
        3. Generates the PDF report and save it in the capture folder. 

    Args:
        capture_folder (str): The capture folder (eg. /tmp/45FB392D/)
    """
    if os.path.isdir(capture_folder):

        alerts = {}
        
        # Create the assets folder.
        if not os.path.isdir(os.path.join(capture_folder, "assets")):
            os.mkdir(os.path.join(capture_folder, "assets"))
        
        # Starts the engine and get alerts
        engine = Engine(capture_folder)
        engine.start_engine()
        alerts = engine.get_alerts()
        analysis_duration = (engine.analysis_end-engine.analysis_start).seconds
        
        # alerts.json writing.
        with open(os.path.join(capture_folder, "assets/alerts.json"), "w") as f:
            report = {"high": [], "moderate": [], "low": []}
            for alert in alerts:
                if alert["level"] == "High":
                    report["high"].append(alert)
                if alert["level"] == "Moderate":
                    report["moderate"].append(alert)
                if alert["level"] == "Low":
                    report["low"].append(alert)
            f.write(json.dumps(report, indent=4, separators=(',', ': ')))

        # records.json writing.
        with open(os.path.join(capture_folder, "assets/records.json"), "w") as f:
            f.write(json.dumps(engine.records, indent=4, separators=(',', ': ')))

        # detection_methods.json writing.
        with open(os.path.join(capture_folder, "assets/detection_methods.json"), "w") as f:
            f.write(json.dumps(engine.detection_methods, indent=4, separators=(',', ': ')))

        # errors.json writing.
        with open(os.path.join(capture_folder, "assets/errors.json"), "w") as f:
            f.write(json.dumps(engine.errors, indent=4, separators=(',', ': ')))

        # Generate the PDF report (optional)
        if HAS_PDF_SUPPORT:
            try:
                report = Report(capture_folder, analysis_duration)
                report.generate_report()
                print("✅ PDF report generated")
            except Exception as e:
                print(f"⚠️  PDF generation failed: {e}")
        else:
            print("ℹ️  Skipping PDF report (weasyprint not available)")

        print("✅ Analysis complete!")

    else:
        print("The folder doesn't exist.")

def usage():
    """Shows the usage output."""
    print(""" Usage: python analysis.py [capture_folder] where [capture_folder] is a folder containing a capture.pcap file """)

if __name__ == "__main__":
    if len(sys.argv) == 2:
        analyze(sys.argv[1])
    else:
        usage()



