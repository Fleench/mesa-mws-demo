#!/bin/bash
set -e

mkdir -p /app/store

# 1. Restore the database from Cloudflare R2
litestream restore -if-db-not-exists -if-replica-exists /app/store/mws.db

# 2. Initialize the MWS store if this is a brand new deployment
if [ ! -f /app/store/mws.db ]; then
  npx mws init-store
fi

# 3. Create a custom "Smart Bridge" to fix the 502 Cold Start bug
cat << 'EOF' > /app/bridge.js
const net = require('net');
const RENDER_PORT = process.env.RENDER_PORT || 10000;

const server = net.createServer((c) => {
    let retries = 0;
    const connect = (host) => {
        const m = net.connect({ port: 8080, host: host }, () => {
            c.pipe(m); m.pipe(c);
        });
        m.on('error', () => {
            // If MWS isn't awake yet, wait 1 second and knock again (up to 15 seconds)
            if (retries < 15) {
                retries++;
                setTimeout(() => connect(host), 1000);
            } else if (host === '::1') {
                retries = 0;
                connect('127.0.0.1'); // Fallback to IPv4
            } else {
                c.end(); // Finally give up
            }
        });
    };
    connect('::1');
    c.on('error', () => {});
});
server.listen(RENDER_PORT, '0.0.0.0', () => console.log('Smart Bridge Active. Holding traffic until MWS boots...'));
EOF

# 4. Start the Smart Bridge
export RENDER_PORT=${PORT:-10000}
export PORT=8080
node /app/bridge.js &

# 5. Boot using the official start script
exec litestream replicate -exec "npm start"
