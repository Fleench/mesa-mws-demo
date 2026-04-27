#!/bin/bash
set -e

mkdir -p /app/store

# 1. Restore the database from Cloudflare R2 (if it exists)
litestream restore -if-db-not-exists -if-replica-exists /app/store/mws.db

# 2. Initialize the MWS store if this is a brand new deployment
if [ ! -f /app/store/mws.db ]; then
  npx mws init-store
fi

# 3. Tell the Node.js server to bind to Render's public network
export HOST=0.0.0.0
export PORT=${PORT:-8080}

# 4. Boot using the official start script scaffolded by MWS
exec litestream replicate -exec "npm start"
