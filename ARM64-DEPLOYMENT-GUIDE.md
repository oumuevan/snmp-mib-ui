# ARM64 架构部署指南

本指南专门针对 ARM64 架构（如 Apple Silicon M1/M2/M3、ARM 服务器）的部署问题和解决方案。

## 🔍 问题诊断

### 常见错误
```bash
E: Failed to fetch https://mirrors.aliyun.com/ubuntu/dists/noble/main/binary-arm64/Packages 404 Not Found
```

**原因分析：**
- 阿里云镜像源对 ARM64 架构支持不完整
- 某些镜像源缺少 ARM64 软件包
- Ubuntu Noble (24.04) 在部分镜像源中 ARM64 支持延迟

## 🛠️ 解决方案

### 1. 自动修复（推荐）

使用更新后的部署脚本，已包含 ARM64 架构检测和多镜像源备选：

```bash
# 运行修复后的部署脚本
bash deploy-china.sh
```

脚本会自动：
- 检测系统架构（ARM64/AMD64）
- 优先使用清华大学镜像源（ARM64 支持完整）
- 备选中科大镜像源
- 最后回退到官方源

### 2. 手动修复软件源

如果自动脚本失败，可手动配置：

#### Ubuntu ARM64 推荐镜像源

```bash
# 备份原始源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 配置清华源（ARM64 支持最佳）
sudo tee /etc/apt/sources.list << 'EOF'
# 清华大学镜像源 - ARM64 完整支持
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF

# 更新软件包列表
sudo apt update
```

#### 备选镜像源

如果清华源不可用，按顺序尝试：

**中科大源：**
```bash
sudo tee /etc/apt/sources.list << 'EOF'
deb https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF
```

**官方源（最稳定）：**
```bash
sudo tee /etc/apt/sources.list << 'EOF'
deb http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
EOF
```

### 3. Docker 多架构支持

#### 启用 Docker Buildx
```bash
# 创建多架构构建器
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap

# 验证支持的架构
docker buildx ls
```

#### ARM64 优化的 Docker 配置

使用项目中的 `docker-compose.china.yml`，已包含 ARM64 优化：

```yaml
services:
  postgres:
    image: registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine
    platform: linux/arm64  # 明确指定架构
    
  redis:
    image: registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine
    platform: linux/arm64
    
  app:
    build:
      context: .
      dockerfile: Dockerfile.china
      platforms:
        - linux/arm64
```

## 🚀 ARM64 快速部署

### 方法一：使用优化脚本

```bash
# 1. 下载项目
git clone <your-repo-url>
cd web-ui

# 2. 运行 ARM64 优化部署
bash deploy-china.sh
```

### 方法二：Docker Compose

```bash
# 1. 配置环境变量
cp .env.example .env
vim .env  # 修改必要配置

# 2. 使用 ARM64 优化配置启动
docker-compose -f docker-compose.china.yml up -d --build
```

### 方法三：手动构建

```bash
# 1. 构建 ARM64 镜像
docker buildx build --platform linux/arm64 -f Dockerfile.china -t mibweb-app:arm64 .

# 2. 启动服务
docker-compose -f docker-compose.china.yml up -d
```

## 🔧 ARM64 特定配置

### Node.js ARM64 优化

在 `Dockerfile.china` 中已包含：

```dockerfile
# 使用 ARM64 优化的 Node.js 镜像
FROM registry.cn-hangzhou.aliyuncs.com/library/node:18-alpine

# 设置 ARM64 特定的 npm 配置
RUN npm config set target_arch arm64
RUN npm config set target_platform linux
RUN npm config set cache /tmp/.npm
```

### Go 后端 ARM64 编译

```dockerfile
# 多阶段构建，支持 ARM64
FROM registry.cn-hangzhou.aliyuncs.com/library/golang:1.21-alpine AS builder

# 设置 ARM64 编译环境
ENV GOOS=linux
ENV GOARCH=arm64
ENV CGO_ENABLED=0

# 使用国内 Go 模块代理
ENV GOPROXY=https://goproxy.cn,direct
```

## 📊 性能优化

### ARM64 特定优化

1. **内存配置**
```bash
# Redis ARM64 优化
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.core.somaxconn = 65535' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

2. **Docker 资源限制**
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'
        reservations:
          memory: 1G
          cpus: '1.0'
```

3. **并发配置**
```bash
# 根据 ARM64 CPU 核心数调整
export GOMAXPROCS=$(nproc)
export NODE_OPTIONS="--max-old-space-size=2048"
```

## 🐛 故障排除

### 常见问题

**1. 软件包架构不匹配**
```bash
# 检查系统架构
uname -m
dpkg --print-architecture

# 清理软件包缓存
sudo apt clean
sudo apt autoclean
sudo apt update
```

**2. Docker 镜像拉取失败**
```bash
# 手动拉取 ARM64 镜像
docker pull --platform linux/arm64 postgres:15-alpine
docker pull --platform linux/arm64 redis:7-alpine
docker pull --platform linux/arm64 node:18-alpine
```

**3. 编译错误**
```bash
# 清理构建缓存
docker system prune -a
docker buildx prune

# 重新构建
docker-compose -f docker-compose.china.yml build --no-cache
```

### 日志检查

```bash
# 检查服务状态
docker-compose -f docker-compose.china.yml ps

# 查看详细日志
docker-compose -f docker-compose.china.yml logs -f app
docker-compose -f docker-compose.china.yml logs -f postgres
docker-compose -f docker-compose.china.yml logs -f redis
```

## 📋 验证清单

部署完成后，验证以下项目：

- [ ] 系统架构检测正确
- [ ] 软件源更新成功
- [ ] Docker 服务正常运行
- [ ] 数据库连接成功
- [ ] Redis 缓存可用
- [ ] 前端页面可访问
- [ ] API 接口响应正常

## 🆘 获取帮助

如果仍然遇到问题：

1. **检查系统信息**
```bash
# 收集系统信息
echo "架构: $(uname -m)"
echo "发行版: $(lsb_release -d)"
echo "内核: $(uname -r)"
echo "Docker: $(docker --version)"
```

2. **提供错误日志**
```bash
# 导出完整日志
docker-compose -f docker-compose.china.yml logs > deployment.log
```

3. **联系技术支持**
- 提供系统信息和错误日志
- 说明具体的部署步骤
- 描述遇到的具体错误

---

**注意：** ARM64 架构部署可能需要更长的构建时间，请耐心等待。建议在网络条件良好的环境下进行部署。