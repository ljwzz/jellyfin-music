# syntax=docker/dockerfile:1.7

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS builder
ARG JELLYFIN_VERSION=10.11.6
WORKDIR /src
RUN apk add --no-cache git icu-data-full
RUN git clone --depth 1 --branch "v${JELLYFIN_VERSION}" https://github.com/jellyfin/jellyfin.git .
RUN dotnet publish Jellyfin.Server \
  -c Release \
  -o /out \
  -p:PublishReadyToRun=true \
  -p:PublishSingleFile=false \
  -p:SelfContained=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
ARG JELLYFIN_VERSION=10.11.6

RUN addgroup -g 109 -S jellyfin \
    && adduser -u 102 -S jellyfin -G jellyfin \
    && apk add --no-cache \
      icu-libs \
      libssl3 \
      ca-certificates \
      fontconfig

WORKDIR /app
COPY --from=builder /out/ /app/

# Keep only runtime-relevant files for a music-only server footprint.
RUN rm -rf /app/wwwroot/videos /app/Samples /app/sample* /app/ffmpeg* \
    && find /app -type f \( -name '*.pdb' -o -name '*.xml' \) -delete

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    JELLYFIN_DATA_DIR=/config \
    JELLYFIN_CACHE_DIR=/cache

VOLUME ["/config", "/cache", "/media"]
EXPOSE 8096
USER jellyfin:jellyfin
ENTRYPOINT ["dotnet", "Jellyfin.Server.dll"]
