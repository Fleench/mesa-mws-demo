FROM node:20-slim

# Install litestream for SQLite database syncing
RUN apt-get update && apt-get install -y curl ca-certificates sqlite3 && \
    curl -L https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz | tar -xz -C /usr/local/bin

# Initialize MWS in the root directory (this creates the 'app' folder automatically)
WORKDIR /
RUN npm init @tiddlywiki/mws@latest app --yes

# Move into the newly created app directory
WORKDIR /app
RUN npm install @tiddlywiki/mws@latest --save-exact

# Copy config and startup scripts
COPY litestream.yml /etc/litestream.yml
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

EXPOSE 8080

CMD ["/app/run.sh"]
