#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, render_template, send_from_directory, redirect, abort, send_file
from app.blueprints.network import network_bp
from app.blueprints.capture import capture_bp
from app.blueprints.capture_filter import capture_filter_bp
from app.blueprints.device import device_bp
from app.blueprints.analysis import analysis_bp
from app.blueprints.save import save_bp
from app.blueprints.misc import misc_bp
from app.utils import read_config
import os

# macOS paths
TEMPLATE_FOLDER = "/opt/spyguard/app/frontend/dist"
MACOS_FRONTEND = "/opt/spyguard/macos-frontend.html"

app = Flask(__name__, template_folder=TEMPLATE_FOLDER)

@app.route("/", methods=["GET"])
def main():
    """
        Return macOS-specific frontend (simpler flow)
    """
    # Check if macOS frontend exists, otherwise use Vue app
    if os.path.exists(MACOS_FRONTEND):
        return send_file(MACOS_FRONTEND)
    return render_template("index.html")

@app.route("/<p>/<path:path>", methods=["GET"])
def get_file(p, path):
    """
        Return the frontend assets (css, js files, fonts etc.)
    """
    rp = "{}/{}".format(TEMPLATE_FOLDER, p)
    return send_from_directory(rp, path) if p in ["css", "fonts", "js", "img"] else redirect("/")

@app.errorhandler(404)
def page_not_found(e):
    return redirect("/")

# API Blueprints.
app.register_blueprint(network_bp, url_prefix='/api/network')
app.register_blueprint(capture_bp, url_prefix='/api/capture')
app.register_blueprint(capture_filter_bp, url_prefix='/api/capture')
app.register_blueprint(device_bp, url_prefix='/api/device')
app.register_blueprint(analysis_bp, url_prefix='/api/analysis')
app.register_blueprint(save_bp, url_prefix='/api/save')
app.register_blueprint(misc_bp, url_prefix='/api/misc')

if __name__ == '__main__':
    port = ""
    try:
        port = int(read_config(("frontend", "http_port")))
    except:
        port = 80
    if read_config(("frontend", "remote_access")):
        app.run(host="0.0.0.0", port=port, threaded=True)
    else:
        app.run(port=port, threaded=True)