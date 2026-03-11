#!/usr/bin/env bash
set -euo pipefail

JELLYFIN_VERSION=$(curl -s https://api.github.com/repos/jellyfin/jellyfin/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')

if [ -z "$JELLYFIN_VERSION" ]; then
    echo "Error: Failed to fetch latest Jellyfin version"
    exit 1
fi

echo "Building Jellyfin Music Server v${JELLYFIN_VERSION}..."

docker build \
    --build-arg JELLYFIN_VERSION="${JELLYFIN_VERSION}" \
    -t "jellyfin-music:${JELLYFIN_VERSION}" \
    -t jellyfin-music:latest \
    .

docker save "jellyfin-music:${JELLYFIN_VERSION}" | gzip > "jellyfin-music-${JELLYFIN_VERSION}.tar.gz"

echo "Done: jellyfin-music-${JELLYFIN_VERSION}.tar.gz"
