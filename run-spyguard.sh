#!/bin/bash
# SpyGuard macOS - Simple Runner

cd /opt/spyguard
source spyguard-venv/bin/activate

echo "Starting SpyGuard..."
echo "Frontend: http://localhost:8000"
echo "Backend:  https://localhost:8443"
echo "Press Ctrl+C to stop"

python3 server/frontend/main.py &
python3 server/backend/main.py &

wait
