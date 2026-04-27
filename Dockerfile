FROM node:20-slim

# Hide the URL in a variable so auto-linkers don't break the build script
ENV LS_URL="https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz"

# Install litestream for SQLite database syncing
RUN apt-get update && apt-get install -y curl ca-certificates sqlite3 && \
    curl -L $LS_URL | tar -xz -C /usr/local/bin

# Initialize MWS. This automatically creates the /app folder AND installs the packages!
WORKDIR /
RUN npm init @tiddlywiki/mws@latest app --yes

# Move into the fully prepared app directory
WORKDIR /app

# Copy config and startup scripts
COPY litestream.yml /etc/litestream.yml
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

EXPOSE 8080

CMD ["/app/run.sh"]
