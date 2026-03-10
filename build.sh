#!/usr/bin/env bash
set -euo pipefail

docker build -t jellyfin-music:10.11.6 .
docker save jellyfin-music:10.11.6 | gzip > jellyfin-music-10.11.6.tar.gz

echo "Done: jellyfin-music-10.11.6.tar.gz"
