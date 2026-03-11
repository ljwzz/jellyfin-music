# Jellyfin Music Server

这是一个针对 **Jellyfin Server** 的“音乐专用精简镜像”工程。

目标是仅保留音乐播放所需能力，移除视频转码与 GPU 相关依赖，自动跟踪 Jellyfin 官方最新版本，并通过 GitHub Actions 自动构建并发布到 Releases。

## 特性

- 基于 Alpine 运行时镜像，尽可能减少镜像体积。
- 支持音乐转码（FLAC → MP3 等），适配不同播放场景。
- 包含 ffmpeg 用于音频格式转换和码率调整。
- 移除视频相关目录、示例文件和调试符号。
- 提供本地一键构建脚本与 GitHub Actions 自动构建流程。

## 为什么比官方镜像更小

本项目通过以下策略减小体积：

- 采用多阶段构建：
  - 构建阶段：`mcr.microsoft.com/dotnet/sdk:9.0-alpine`
  - 运行阶段：`mcr.microsoft.com/dotnet/aspnet:9.0-alpine`（最终镜像基座）
- 仅安装最小运行依赖：
  - `ffmpeg`（用于音频转码）
  - `icu-libs`
  - `libssl3`
  - `ca-certificates`
  - `fontconfig`
- 不包含以下组件：
  - GPU 驱动
  - VAAPI / NVENC / Intel QSV
  - 视频 codec 相关工具链
- 发布后清理调试与示例文件（如 `*.pdb`、`*.xml`、sample 目录等）。

> **版本策略**：本项目自动跟踪 Jellyfin 官方最新版本，无需手动更新版本号。
>
> **镜像体积**：**250MB - 350MB**（含 ffmpeg，具体取决于上游依赖变化和构建时刻）。
>
> **技术栈**：基于 .NET 9（SDK 9.0 + ASP.NET Runtime 9.0）构建。

## 目录结构

```text
.
├── Dockerfile
├── docker-compose.yml
├── build.sh
├── .github/workflows/build.yml
└── README.md
```

## 快速开始

### 方式一：从 Releases 下载（推荐）

访问 [Releases 页面](https://github.com/OWNER/REPO/releases) 下载最新版本：

```bash
# 下载最新版本
curl -L -o jellyfin-music.tar.gz https://github.com/OWNER/REPO/releases/latest/download/jellyfin-music-LATEST_VERSION.tar.gz

# 导入镜像
gzip -dc jellyfin-music.tar.gz | docker load

# 启动容器
docker run -d \
  --name jellyfin \
  --user 102:109 \
  -p 127.0.0.1:18096:8096 \
  -v /opt/jellyfin/config:/config \
  -v /opt/jellyfin/cache:/cache \
  -v /media:/media:ro \
  --restart unless-stopped \
  jellyfin-music:latest
```

### 方式二：本地构建

如果你想本地构建特定版本：

```bash
./build.sh
```

该脚本会自动查询 Jellyfin 最新版本并构建。

### 使用 docker compose

```bash
# 先修改 docker-compose.yml 中的镜像版本
docker compose up -d
```

`docker-compose.yml` 已提供与 `docker run` 等效的配置。

## 自动版本跟踪与发布

本项目自动跟踪 Jellyfin 官方最新版本：

- **查询方式**：通过 GitHub API 获取 `jellyfin/jellyfin` 最新 Release
- **构建触发**：每周日自动检查新版本，或手动触发
- **发布位置**：构建产物直接发布到 [GitHub Releases](https://github.com/OWNER/REPO/releases)

### GitHub Actions 工作流

文件：`.github/workflows/build.yml`

触发条件：

- `push` 到 main/master 分支
- `workflow_dispatch` 手动触发
- `schedule` 每周日自动检查

执行流程：

1. 查询 Jellyfin 最新版本
2. 构建镜像（传入动态版本号）
3. 打包为 tar.gz
4. 创建 GitHub Release 并上传产物

### 本地构建特定版本

如需构建特定版本：

```bash
docker build --build-arg JELLYFIN_VERSION=10.11.6 -t jellyfin-music:10.11.6 .
```
