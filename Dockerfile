FROM node:20-slim

# Install litestream for SQLite database syncing
RUN apt-get update && apt-get install -y curl ca-certificates sqlite3 && \
    curl -L https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz | tar -xz -C /usr/local/bin

WORKDIR /app

# Install MultiWikiServer
RUN npm init @tiddlywiki/mws@latest . --yes && \
    npm install @tiddlywiki/mws@latest --save-exact

# Copy config and startup scripts
COPY litestream.yml /etc/litestream.yml
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Render uses the PORT environment variable, MWS defaults to 8080
EXPOSE 8080

CMD ["/app/run.sh"]
