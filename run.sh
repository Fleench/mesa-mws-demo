#!/bin/bash
set -e

mkdir -p /app/store

# 1. Restore the database from Cloudflare R2
litestream restore -if-db-not-exists -if-replica-exists /app/store/mws.db

# 2. Initialize the MWS store if this is a brand new deployment
if [ ! -f /app/store/mws.db ]; then
  npx mws init-store
fi

# 3. Smart Bridge v2: Fixes Cold Starts AND Auto-Routes the homepage
cat << 'EOF' > /app/bridge.js
const net = require('net');
const RENDER_PORT = process.env.RENDER_PORT || 10000;

// CHANGE 'default' if you named your recipe something else!
const TARGET_WIKI = '/wiki/Mesa%20Web'; 

const server = net.createServer((c) => {
    let retries = 0;
    
    // Listen for the very first packet from the browser
    c.once('data', (data) => {
        const req = data.toString();
        
        // THE AUTO-ROUTER: If they hit the bare URL, bounce them to the Wiki
        if (req.startsWith('GET / HTTP/')) {
            const res = `HTTP/1.1 302 Found\r\nLocation: ${TARGET_WIKI}\r\nConnection: close\r\n\r\n`;
            c.write(res);
            c.end();
            return;
        }

        // NORMAL TRAFFIC: Hand everything else over to MWS
        const connect = (host) => {
            const m = net.connect({ port: 8080, host: host }, () => {
                m.write(data); // Pass the intercepted first packet
                c.pipe(m); 
                m.pipe(c);
            });
            m.on('error', () => {
                if (retries < 15) {
                    retries++;
                    setTimeout(() => connect(host), 1000);
                } else if (host === '::1') {
                    retries = 0;
                    connect('127.0.0.1');
                } else {
                    c.end();
                }
            });
        };
        connect('::1');
    });
    c.on('error', () => {});
});
server.listen(RENDER_PORT, '0.0.0.0', () => console.log('Smart Bridge v2 Active.'));
EOF

# 4. Start the Smart Bridge
export RENDER_PORT=${PORT:-10000}
export PORT=8080
node /app/bridge.js &

# 5. Boot using the official start script
exec litestream replicate -exec "npm start"
