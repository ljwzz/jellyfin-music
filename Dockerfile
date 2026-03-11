# syntax=docker/dockerfile:1.7

FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS builder
ARG JELLYFIN_VERSION
WORKDIR /src
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN apk add --no-cache git icu-data-full
RUN git clone --depth 1 --branch "v${JELLYFIN_VERSION}" https://github.com/jellyfin/jellyfin.git .
RUN dotnet publish Jellyfin.Server \
  -c Release \
  -o /out \
  -p:PublishReadyToRun=true \
  -p:PublishSingleFile=false \
  -p:SelfContained=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS runtime
ARG JELLYFIN_VERSION

RUN addgroup -g 109 -S jellyfin \
    && adduser -u 102 -S jellyfin -G jellyfin \
    && apk add --no-cache \
      ffmpeg \
      icu-libs \
      libssl3 \
      ca-certificates \
      fontconfig \
    && mkdir -p /cache /config /media \
    && chmod 777 /cache /config /media

WORKDIR /app
COPY --from=builder /out/ /app/

RUN rm -rf /app/wwwroot/videos /app/Samples /app/sample* \
    && find /app -type f \( -name '*.pdb' -o -name '*.xml' \) -delete

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

VOLUME ["/config", "/cache", "/media"]
EXPOSE 8096
USER jellyfin:jellyfin
ENTRYPOINT ["dotnet", "jellyfin.dll", "--datadir", "/config", "--cachedir", "/cache"]
