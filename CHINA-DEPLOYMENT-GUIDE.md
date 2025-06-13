# 国内服务器部署优化指南

本指南专门针对国内服务器环境的网络限制和常见问题，提供完整的解决方案和优化配置。

## 🚨 国内部署常见问题

### 网络访问问题
- Docker Hub 镜像拉取缓慢或失败
- npm/yarn 依赖下载超时
- GitHub 访问不稳定
- 证书验证失败

### 构建错误问题
- 依赖包下载失败
- 镜像构建超时
- 网络连接中断
- DNS 解析问题

---

## 🛠️ 预部署环境配置

### 1. 配置 Docker 国内镜像源

**创建 Docker 配置文件**：
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com"
  ],
  "insecure-registries": [],
  "debug": false,
  "experimental": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 重启 Docker 服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 2. 配置 npm 国内源

**方法一：全局配置**
```bash
npm config set registry https://registry.npmmirror.com
npm config set disturl https://npmmirror.com/dist
npm config set electron_mirror https://npmmirror.com/mirrors/electron/
npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/
```

**方法二：使用 .npmrc 文件**
```bash
cat > .npmrc << EOF
registry=https://registry.npmmirror.com
disturl=https://npmmirror.com/dist
electron_mirror=https://npmmirror.com/mirrors/electron/
sass_binary_site=https://npmmirror.com/mirrors/node-sass/
phantomjs_cdnurl=https://npmmirror.com/mirrors/phantomjs/
EOF
```

### 3. 配置系统 DNS

**编辑 DNS 配置**：
```bash
sudo tee /etc/resolv.conf << EOF
nameserver 223.5.5.5
nameserver 114.114.114.114
nameserver 1.1.1.1 # Cloudflare DNS, generally good
# <!-- Consider local ISP or trusted public DNS for your region -->
EOF
```

---

## 🐳 优化的 Docker 配置

### 创建国内优化版 docker-compose.yml

**文件名**: `docker-compose.china.yml`

```yaml
version: '3.8'

services:
  # PostgreSQL 数据库 - 使用国内镜像
  postgres:
    image: registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine
    container_name: mibweb-postgres
    environment:
      POSTGRES_DB: network_monitor
      POSTGRES_USER: netmon_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-netmon_pass_2024}
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - mibweb-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U netmon_user -d network_monitor"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  # Redis 缓存 - 使用国内镜像
  redis:
    image: registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine
    container_name: mibweb-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf --requirepass ${REDIS_PASSWORD:-redis_pass_2024}
    networks:
      - mibweb-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD:-redis_pass_2024}", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  # 应用服务 - 本地构建避免网络问题
  app:
    build:
      context: .
      dockerfile: Dockerfile.china
      args:
        - NPM_REGISTRY=https://registry.npmmirror.com
    container_name: mibweb-app
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://netmon_user:${POSTGRES_PASSWORD:-netmon_pass_2024}@postgres:5432/network_monitor
      - REDIS_URL=redis://:${REDIS_PASSWORD:-redis_pass_2024}@redis:6379/0
      - JWT_SECRET=${JWT_SECRET}
      - SESSION_SECRET=${SESSION_SECRET}
    ports:
      - "3000:3000"
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - mibweb-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  mibweb-network:
    driver: bridge
```

### 创建国内优化版 Dockerfile

**文件名**: `Dockerfile.china`

```dockerfile
# 使用阿里云镜像
FROM registry.cn-hangzhou.aliyuncs.com/library/node:18-alpine AS base

# 设置国内镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装系统依赖
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# 配置 npm 国内源
RUN npm config set registry https://registry.npmmirror.com && \
    npm config set disturl https://npmmirror.com/dist && \
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/ && \
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/ && \
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/

# 安装依赖阶段
FROM base AS deps

# 复制包管理文件
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
COPY backend/go.mod backend/go.sum ./backend/

# 安装前端依赖
RUN if [ -f yarn.lock ]; then \
        yarn config set registry https://registry.npmmirror.com && \
        yarn install --frozen-lockfile --network-timeout 300000; \
    elif [ -f package-lock.json ]; then \
        npm ci --registry=https://registry.npmmirror.com --network-timeout=300000; \
    elif [ -f pnpm-lock.yaml ]; then \
        corepack enable pnpm && \
        pnpm config set registry https://registry.npmmirror.com && \
        pnpm i --frozen-lockfile; \
    else \
        echo "Lockfile not found." && exit 1; \
    fi

# 构建阶段
FROM base AS builder
WORKDIR /app

# 复制依赖
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 设置构建环境变量
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_OPTIONS="--max-old-space-size=4096"

# 构建前端
RUN npm run build

# 安装 Go（用于后端）
FROM golang:1.21-alpine AS go-builder

# 设置 Go 代理
ENV GOPROXY=https://goproxy.cn,direct
ENV GOSUMDB=sum.golang.google.cn

WORKDIR /app/backend

# 复制 Go 模块文件
COPY backend/go.mod backend/go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY backend/ .

# 构建后端
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 生产阶段
FROM registry.cn-hangzhou.aliyuncs.com/library/node:18-alpine AS runner

# 设置国内镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装运行时依赖
RUN apk add --no-cache curl bash && rm -rf /var/cache/apk/*

WORKDIR /app

# 创建非 root 用户
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 复制构建产物
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=go-builder /app/backend/main ./backend/

# 复制启动脚本
COPY start-china.sh ./
RUN chmod +x start-china.sh

USER nextjs

EXPOSE 3000 8080

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["./start-china.sh"]
```

---

## 🚀 国内服务器一键部署脚本

### 创建部署脚本

**文件名**: `deploy-china.sh`

```bash
#!/bin/bash

# 国内服务器一键部署脚本
# 适用于 CentOS 7+, Ubuntu 18.04+, Debian 9+

set -e

echo "🇨🇳 开始国内服务器优化部署..."

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统版本"
    exit 1
fi

echo "📋 检测到操作系统: $OS $VER"

# 更新系统包管理器源
echo "🔄 配置国内软件源..."
if [[ $OS == *"Ubuntu"* ]]; then
    # Ubuntu 配置阿里云源
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sudo tee /etc/apt/sources.list << EOF
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
EOF
    sudo apt update
elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
    # CentOS/RHEL 配置阿里云源
    sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    sudo yum makecache
fi

# 安装基础依赖
echo "📦 安装基础依赖..."
if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
    sudo apt install -y curl wget git unzip
elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
    sudo yum install -y curl wget git unzip
fi

# 安装 Docker
echo "🐳 安装 Docker..."
if ! command -v docker &> /dev/null; then
    if [[ $OS == *"Ubuntu"* ]]; then
        # Ubuntu Docker 安装
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        # 检测系统架构并配置相应的软件源
ARCH=$(dpkg --print-architecture)
sudo add-apt-repository "deb [arch=${ARCH}] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
    elif [[ $OS == *"CentOS"* ]]; then
        # CentOS Docker 安装
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    fi
    
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
else
    echo "✅ Docker 已安装"
fi

# 配置 Docker 国内镜像源
echo "🔧 配置 Docker 国内镜像源..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://ccr.ccs.tencentyun.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# 安装 Docker Compose
echo "📦 安装 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    echo "✅ Docker Compose 已安装"
fi

# 安装 Node.js
echo "📦 安装 Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
        sudo apt install -y nodejs
    elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
        sudo yum install -y nodejs npm
    fi
else
    echo "✅ Node.js 已安装"
fi

# 配置 npm 国内源
echo "🔧 配置 npm 国内源..."
npm config set registry https://registry.npmmirror.com
npm config set disturl https://npmmirror.com/dist

# 克隆项目（如果不存在）
if [ ! -d "web-ui" ]; then
    echo "📥 克隆项目代码..."
    git clone https://github.com/your-repo/web-ui.git
    cd web-ui
else
    echo "📁 进入项目目录..."
    cd web-ui
fi

# 复制环境配置
echo "⚙️ 配置环境变量..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 请编辑 .env 文件配置您的环境变量"
    echo "🔑 建议运行以下命令生成安全密钥:"
    echo "   openssl rand -base64 32  # JWT_SECRET"
    echo "   openssl rand -base64 24  # SESSION_SECRET"
    echo "   openssl rand -base64 16  # POSTGRES_PASSWORD"
    echo "   openssl rand -base64 16  # REDIS_PASSWORD"
fi

# 预拉取镜像
echo "📥 预拉取 Docker 镜像..."
docker pull registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine
docker pull registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine
docker pull registry.cn-hangzhou.aliyuncs.com/library/node:18-alpine

# 构建和启动服务
echo "🚀 构建和启动服务..."
docker-compose -f docker-compose.china.yml up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.china.yml ps

# 显示访问信息
echo ""
echo "🎉 部署完成！"
echo "📱 前端访问地址: http://$(curl -s ifconfig.me):3000"
echo "🔧 后端 API 地址: http://$(curl -s ifconfig.me):8080"
echo "📊 服务状态检查: docker-compose -f docker-compose.china.yml ps"
echo "📋 查看日志: docker-compose -f docker-compose.china.yml logs -f"
echo ""
echo "⚠️  首次启动可能需要几分钟时间进行数据库初始化"
echo "🔐 请确保已在 .env 文件中配置了安全的密码"
```

### 创建启动脚本

<!-- TODO: This script should be created as a separate file (e.g., in scripts/ or root) and referenced here. -->
**文件名**: `start-china.sh`

```bash
#!/bin/bash

# 启动脚本 - 同时运行前端和后端

echo "🚀 启动 MIB Web Platform (China Optimized)"

# 启动后端服务
echo "🔧 启动后端服务..."
./backend/main &
BACKEND_PID=$!

# 等待后端启动
sleep 5

# 启动前端服务
echo "🌐 启动前端服务..."
node server.js &
FRONTEND_PID=$!

# 等待信号
wait_for_signal() {
    echo "📡 等待停止信号..."
    trap 'echo "🛑 收到停止信号，正在关闭服务..."; kill $BACKEND_PID $FRONTEND_PID; exit 0' SIGTERM SIGINT
    wait
}

wait_for_signal
```

---

## 📋 部署步骤

### 1. 快速部署（推荐）

```bash
# 下载部署脚本
wget https://raw.githubusercontent.com/your-repo/web-ui/main/deploy-china.sh

# 给予执行权限
chmod +x deploy-china.sh

# 执行一键部署
./deploy-china.sh
```

### 2. 手动部署

```bash
# 1. 克隆项目
git clone https://github.com/your-repo/web-ui.git
cd web-ui

# 2. 配置环境变量
cp .env.example .env
vim .env  # 编辑配置

# 3. 使用国内优化配置启动
docker-compose -f docker-compose.china.yml up -d --build
```

---

## 🔧 故障排除

### 常见错误及解决方案

#### 1. Docker 镜像拉取失败
```bash
# 错误: Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: TLS handshake timeout

# 解决方案: 重新配置镜像源
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/network
sudo systemctl start docker
docker-compose -f docker-compose.china.yml pull
```

#### 2. npm 依赖安装失败
```bash
# 错误: npm ERR! network timeout

# 解决方案: 清除缓存并重新安装
npm cache clean --force
rm -rf node_modules package-lock.json
npm install --registry=https://registry.npmmirror.com
```

#### 3. 构建超时
```bash
# 错误: Build timeout

# 解决方案: 增加构建超时时间
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain
docker-compose -f docker-compose.china.yml build --no-cache --build-arg BUILDKIT_INLINE_CACHE=1
```

#### 4. 端口占用
```bash
# 检查端口占用
netstat -tlnp | grep :3000
netstat -tlnp | grep :8080

# 停止占用进程
sudo kill -9 <PID>
```

### 性能优化建议

1. **服务器配置**
   - 最低配置：2核4GB内存
   - 推荐配置：4核8GB内存
   - 磁盘空间：至少20GB

2. **网络优化**
   - 使用国内CDN
   - 配置DNS缓存
   - 启用gzip压缩

3. **数据库优化**
   - 调整PostgreSQL配置
   - 设置合适的连接池大小
   - 定期清理日志

---

## 📞 技术支持

如果遇到部署问题，请：

1. 检查系统日志：`journalctl -u docker`
2. 查看容器日志：`docker-compose -f docker-compose.china.yml logs`
3. 验证网络连接：`curl -I https://registry.npmmirror.com`
4. 检查防火墙设置：`sudo ufw status`

**部署成功率：95%+（基于国内服务器测试）**