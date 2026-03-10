# Jellyfin Music Server (10.11.6)

这是一个针对 **Jellyfin Server 10.11.6** 的“音乐专用精简镜像”工程。

目标是仅保留音乐播放所需能力，去除视频转码与 GPU 相关依赖，并通过 GitHub Actions 自动构建后输出可分发的 `docker save` 压缩包 artifact。

## 为什么比官方镜像更小

本项目通过以下策略减小体积：

- 使用 `mcr.microsoft.com/dotnet/aspnet:8.0-alpine` 作为运行时基础镜像（Alpine 更轻量）。
- 仅安装最小运行依赖：
  - .NET 8 runtime（由 aspnet 基础镜像提供）
  - `libicu`（Alpine 包名：`icu-libs`）
  - `libssl3`
  - `ca-certificates`
  - `fontconfig`
- 不包含以下组件：
  - `ffmpeg`
  - GPU 驱动
  - VAAPI / NVENC / Intel QSV
  - 视频 codec 相关工具链
- 发布后清理调试与示例文件（如 `*.pdb`、`*.xml`、sample 目录等）。

> 预估镜像体积：**200MB - 280MB**（具体取决于上游依赖变化和构建时刻）。

## 目录结构

```text
.
├── Dockerfile
├── docker-compose.yml
├── build.sh
├── .github/workflows/build.yml
└── README.md
```

## 本地构建并导出镜像

在项目根目录执行：

```bash
./build.sh
```

该脚本会生成：

- `jellyfin-music-10.11.6.tar.gz`

## 使用方法

### 1) docker load

```bash
gzip -dc jellyfin-music-10.11.6.tar.gz | docker load
```

### 2) docker run

```bash
docker run -d \
  --name jellyfin \
  --user 102:109 \
  -p 127.0.0.1:18096:8096 \
  -v /opt/jellyfin/config:/config \
  -v /opt/jellyfin/cache:/cache \
  -v /media:/media:ro \
  --restart unless-stopped \
  jellyfin-music:10.11.6
```

### 3) docker-compose 示例

```bash
docker compose up -d
```

`docker-compose.yml` 已提供与上面等效的配置。

## GitHub Actions 产物

工作流文件：`.github/workflows/build.yml`

触发方式：

- `push`
- `workflow_dispatch`

执行流程：

1. Checkout
2. Setup Docker Buildx
3. 构建镜像 `jellyfin-music:10.11.6`
4. `docker save | gzip > jellyfin-music.tar.gz`
5. 上传 artifact：`jellyfin-music-docker-image`

最终 artifact 文件名：

- `jellyfin-music.tar.gz`
