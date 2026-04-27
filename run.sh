#!/bin/bash
set -e

mkdir -p /app/store

# 1. Restore the database from Cloudflare R2
litestream restore -if-db-not-exists -if-replica-exists /app/store/mws.db

# 2. Initialize the MWS store if this is a brand new deployment
if [ ! -f /app/store/mws.db ]; then
  npx mws init-store
fi

# 3. THE HACKER BRIDGE (Fixed for IPv6 mismatch causing 502)
# Render assigns a public port (usually 10000). We save it safely.
export RENDER_PORT=${PORT:-10000}

# We force MWS to run on an internal port (8080) so there are no port conflicts.
export PORT=8080

# Start socat in the background to pipe Render's public IPv4 traffic into MWS's secure IPv6 bubble.
socat TCP4-LISTEN:${RENDER_PORT},fork,bind=0.0.0.0 TCP6:[::1]:8080 &

# 4. Boot using the official start script
exec litestream replicate -exec "npm start"
