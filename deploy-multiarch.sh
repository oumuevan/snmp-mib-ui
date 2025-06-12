#!/bin/bash

# Multi-Architecture Deployment Script
# Automatically detects architecture and deploys optimally
# Supports AMD64, ARM64, and ARMv7 architectures

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

error_exit() {
    log_error "$1"
    exit 1
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "    🚀 MIB Web Platform - Multi-Architecture Deployment"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# 检测系统架构
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/redhat-release ]; then
        echo "centos"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 检测系统信息
detect_system_info() {
    ARCH=$(detect_architecture)
    OS=$(detect_os)
    CPU_CORES=$(nproc)
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    
    log_info "系统信息检测完成:"
    echo "  架构: $ARCH"
    echo "  操作系统: $OS"
    echo "  CPU 核心: $CPU_CORES"
    echo "  内存: ${MEMORY_GB}GB"
    echo "  可用磁盘: ${DISK_GB}GB"
}

# 检查系统要求
check_system_requirements() {
    log_step "检查系统要求..."
    
    # 检查内存
    if [ "$MEMORY_GB" -lt 2 ]; then
        error_exit "内存不足 2GB，当前: ${MEMORY_GB}GB"
    fi
    
    # 检查磁盘空间
    if [ "$DISK_GB" -lt 10 ]; then
        error_exit "磁盘空间不足 10GB，当前: ${DISK_GB}GB"
    fi
    
    # 架构支持检查
    case $ARCH in
        "amd64"|"arm64")
            log_success "架构 $ARCH 完全支持"
            ;;
        "armv7")
            log_warning "架构 $ARCH 部分支持，性能可能受限"
            ;;
        "unknown")
            error_exit "不支持的架构: $(uname -m)"
            ;;
    esac
}

# 配置软件源（架构特定）
configure_package_sources() {
    log_step "配置软件源 (架构: $ARCH)..."
    
    case $OS in
        "ubuntu"|"debian")
            configure_debian_sources
            ;;
        "centos"|"rhel"|"rocky")
            configure_rhel_sources
            ;;
        *)
            log_warning "未知操作系统 $OS，跳过软件源配置"
            ;;
    esac
}

# 配置 Debian/Ubuntu 软件源
configure_debian_sources() {
    local codename=$(lsb_release -cs 2>/dev/null || echo "focal")
    
    # 备份原始源
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d-%H%M%S)
    
    # 根据架构选择最优镜像源
    case $ARCH in
        "amd64")
            configure_amd64_sources $codename
            ;;
        "arm64")
            configure_arm64_sources $codename
            ;;
        "armv7")
            configure_armv7_sources $codename
            ;;
    esac
    
    # 更新软件包列表
    sudo apt update || {
        log_warning "软件源更新失败，尝试恢复原始源"
        sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
        sudo apt update
    }
}

# AMD64 架构软件源配置
configure_amd64_sources() {
    local codename=$1
    log_info "配置 AMD64 软件源..."
    
    sudo tee /etc/apt/sources.list << EOF
# 阿里云镜像源 - AMD64 完整支持
deb https://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse
EOF
}

# ARM64 架构软件源配置
configure_arm64_sources() {
    local codename=$1
    log_info "配置 ARM64 软件源..."
    
    # 备份原始源文件
    if [ -f /etc/apt/sources.list ]; then
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    fi
    
    # 尝试多个镜像源，优先使用阿里云（ARM64 支持稳定）
    log_info "尝试配置阿里云镜像源（ARM64 支持稳定）..."
    sudo tee /etc/apt/sources.list << EOF
# 阿里云镜像源 - ARM64 支持稳定
deb https://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse
EOF
    
    # 测试软件源可用性
    if ! sudo apt update 2>/dev/null; then
        log_warning "阿里云镜像源不可用，尝试华为云镜像源..."
        sudo tee /etc/apt/sources.list << EOF
# 华为云镜像源 - ARM64 备选
deb https://mirrors.huaweicloud.com/ubuntu/ $codename main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ $codename-updates main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ $codename-backports main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ $codename-security main restricted universe multiverse
EOF
        
        if ! sudo apt update 2>/dev/null; then
             log_warning "华为云镜像源不可用，使用官方源..."
             sudo tee /etc/apt/sources.list << EOF
 # Ubuntu 官方源 - ARM64 完整支持
 deb http://ports.ubuntu.com/ubuntu-ports/ $codename main restricted universe multiverse
 deb http://ports.ubuntu.com/ubuntu-ports/ $codename-updates main restricted universe multiverse
 deb http://ports.ubuntu.com/ubuntu-ports/ $codename-backports main restricted universe multiverse
 deb http://ports.ubuntu.com/ubuntu-ports/ $codename-security main restricted universe multiverse
 EOF
             
             # 最后测试官方源
             if ! sudo apt update 2>/dev/null; then
                 log_error "所有镜像源都不可用，恢复原始配置..."
                 if [ -f /etc/apt/sources.list.backup ]; then
                     sudo cp /etc/apt/sources.list.backup /etc/apt/sources.list
                     log_info "已恢复原始软件源配置"
                 else
                     log_error "无法恢复原始配置，请手动检查网络连接"
                     exit 1
                 fi
             fi
        fi
    fi
}

# ARMv7 架构软件源配置
configure_armv7_sources() {
    local codename=$1
    log_info "配置 ARMv7 软件源..."
    
    # 使用官方源（ARMv7 支持最稳定）
    sudo tee /etc/apt/sources.list << EOF
# Ubuntu 官方源 - ARMv7 支持
deb http://ports.ubuntu.com/ubuntu-ports/ $codename main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $codename-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $codename-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $codename-security main restricted universe multiverse
EOF
}

# 配置 RHEL/CentOS 软件源
configure_rhel_sources() {
    log_info "配置 RHEL/CentOS 软件源..."
    
    # 备份原始源
    sudo cp -r /etc/yum.repos.d /etc/yum.repos.d.backup.$(date +%Y%m%d-%H%M%S)
    
    # 配置阿里云源
    case $ARCH in
        "amd64")
            sudo wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
            ;;
        "arm64")
            log_warning "ARM64 CentOS 支持有限，建议使用 Ubuntu"
            ;;
    esac
    
    sudo yum clean all
    sudo yum makecache
}

# 安装 Docker（架构特定）
install_docker() {
    log_step "安装 Docker (架构: $ARCH)..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker 已安装: $(docker --version)"
        return 0
    fi
    
    case $OS in
        "ubuntu"|"debian")
            install_docker_debian
            ;;
        "centos"|"rhel"|"rocky")
            install_docker_rhel
            ;;
        *)
            error_exit "不支持的操作系统: $OS"
            ;;
    esac
    
    # 启动 Docker 服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加用户到 docker 组
    sudo usermod -aG docker $USER
    
    log_success "Docker 安装完成"
}

# 在 Debian/Ubuntu 上安装 Docker
install_docker_debian() {
    # 安装依赖
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加 Docker GPG 密钥
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加 Docker 仓库
    case $ARCH in
        "amd64")
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
            ;;
        "arm64")
            echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
            ;;
        "armv7")
            echo "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
            ;;
    esac
    
    # 安装 Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
}

# 在 RHEL/CentOS 上安装 Docker
install_docker_rhel() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
}

# 安装 Docker Compose
install_docker_compose() {
    log_step "安装 Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose 已安装: $(docker-compose --version)"
        return 0
    fi
    
    # 根据架构下载对应版本
    local compose_version="2.20.2"
    local compose_arch
    
    case $ARCH in
        "amd64")
            compose_arch="x86_64"
            ;;
        "arm64")
            compose_arch="aarch64"
            ;;
        "armv7")
            compose_arch="armv7"
            ;;
        *)
            error_exit "不支持的架构: $ARCH"
            ;;
    esac
    
    # 下载并安装
    sudo curl -L "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${compose_arch}" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建符号链接
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose 安装完成"
}

# 配置 Docker 镜像源
configure_docker_registry() {
    log_step "配置 Docker 镜像源..."
    
    sudo mkdir -p /etc/docker
    
    # 根据架构选择最优镜像源
    case $ARCH in
        "amd64")
            configure_amd64_docker_registry
            ;;
        "arm64")
            configure_arm64_docker_registry
            ;;
        "armv7")
            configure_armv7_docker_registry
            ;;
    esac
    
    sudo systemctl restart docker
    log_success "Docker 镜像源配置完成"
}

# AMD64 Docker 镜像源配置
configure_amd64_docker_registry() {
    sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
}

# ARM64 Docker 镜像源配置
configure_arm64_docker_registry() {
    sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "memlock": {
      "name": "memlock",
      "soft": -1,
      "hard": -1
    }
  }
}
EOF
}

# ARMv7 Docker 镜像源配置
configure_armv7_docker_registry() {
    sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "2"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "memlock": {
      "name": "memlock",
      "soft": 65536,
      "hard": 65536
    }
  }
}
EOF
}

# 启用 Docker Buildx（多架构支持）
setup_docker_buildx() {
    log_step "设置 Docker Buildx (多架构支持)..."
    
    # 创建多架构构建器
    docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || true
    docker buildx inspect --bootstrap
    
    # 验证支持的架构
    log_info "支持的架构:"
    docker buildx ls | grep multiarch
    
    log_success "Docker Buildx 设置完成"
}

# 配置环境变量
configure_environment() {
    log_step "配置环境变量..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            log_info "已复制 .env.example 到 .env"
        else
            create_default_env
        fi
    fi
    
    # 生成安全密钥
    generate_secure_keys
    
    log_success "环境变量配置完成"
}

# 创建默认环境配置
create_default_env() {
    log_info "创建默认环境配置..."
    
    cat > .env << 'EOF'
# MIB Web Platform - Multi-Architecture Configuration

# 数据库配置
POSTGRES_PASSWORD=netmon_pass_2024
DATABASE_URL=postgresql://netmon_user:netmon_pass_2024@postgres:5432/network_monitor

# Redis 配置
REDIS_PASSWORD=redis_pass_2024
REDIS_URL=redis://:redis_pass_2024@redis:6379/0

# 应用配置
NODE_ENV=production
NEXT_PUBLIC_API_URL=http://localhost:8080
FRONTEND_URL=http://localhost:3000
CORS_ORIGINS=http://localhost:3000

# 安全配置（将被自动生成的密钥替换）
JWT_SECRET=REPLACE_WITH_SECURE_KEY
SESSION_SECRET=REPLACE_WITH_SECURE_KEY
NEXTAUTH_SECRET=REPLACE_WITH_SECURE_KEY

# 架构特定配置
TARGETARCH=REPLACE_WITH_DETECTED_ARCH
EOF
}

# 生成安全密钥
generate_secure_keys() {
    log_info "生成安全密钥..."
    
    # 生成随机密钥
    JWT_SECRET=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    NEXTAUTH_SECRET=$(openssl rand -hex 32)
    
    # 更新 .env 文件
    sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    sed -i "s/SESSION_SECRET=.*/SESSION_SECRET=$SESSION_SECRET/" .env
    sed -i "s/NEXTAUTH_SECRET=.*/NEXTAUTH_SECRET=$NEXTAUTH_SECRET/" .env
    sed -i "s/TARGETARCH=.*/TARGETARCH=$ARCH/" .env
    
    log_success "安全密钥生成完成"
}

# 预拉取镜像
pull_images() {
    log_step "预拉取 Docker 镜像 (架构: $ARCH)..."
    
    local images=()
    
    case $ARCH in
        "amd64")
            images=(
                "postgres:15-alpine"
                "redis:7-alpine"
                "node:18-alpine"
                "golang:1.21-alpine"
                "nginx:alpine"
            )
            ;;
        "arm64")
            images=(
                "--platform=linux/arm64 postgres:15-alpine"
                "--platform=linux/arm64 redis:7-alpine"
                "--platform=linux/arm64 node:18-alpine"
                "--platform=linux/arm64 golang:1.21-alpine"
                "--platform=linux/arm64 nginx:alpine"
            )
            ;;
        "armv7")
            images=(
                "--platform=linux/arm/v7 postgres:15-alpine"
                "--platform=linux/arm/v7 redis:7-alpine"
                "--platform=linux/arm/v7 node:18-alpine"
                "--platform=linux/arm/v7 nginx:alpine"
            )
            ;;
    esac
    
    for image in "${images[@]}"; do
        log_info "拉取镜像: $image"
        docker pull $image || log_warning "镜像拉取失败: $image"
    done
    
    log_success "镜像预拉取完成"
}

# 构建应用
build_application() {
    log_step "构建应用 (架构: $ARCH)..."
    
    # 选择合适的 Docker Compose 文件
    local compose_file
    case $ARCH in
        "amd64")
            compose_file="docker-compose.yml"
            ;;
        "arm64"|"armv7")
            compose_file="docker-compose.multiarch.yml"
            ;;
    esac
    
    if [ ! -f "$compose_file" ]; then
        log_warning "$compose_file 不存在，使用 docker-compose.china.yml"
        compose_file="docker-compose.china.yml"
    fi
    
    log_info "使用配置文件: $compose_file"
    
    # 构建应用
    TARGETARCH=$ARCH docker-compose -f $compose_file build --no-cache
    
    log_success "应用构建完成"
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    # 选择合适的 Docker Compose 文件
    local compose_file
    case $ARCH in
        "amd64")
            compose_file="docker-compose.yml"
            ;;
        "arm64"|"armv7")
            compose_file="docker-compose.multiarch.yml"
            ;;
    esac
    
    if [ ! -f "$compose_file" ]; then
        compose_file="docker-compose.china.yml"
    fi
    
    # 启动服务
    TARGETARCH=$ARCH docker-compose -f $compose_file up -d
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_step "等待服务就绪..."
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            log_success "服务就绪检查通过"
            return 0
        fi
        
        log_info "等待服务就绪... ($attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "服务启动超时"
    return 1
}

# 显示部署结果
show_deployment_result() {
    echo -e "${GREEN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "    🎉 MIB Web Platform 部署成功！"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    
    echo "📊 部署信息:"
    echo "  架构: $ARCH"
    echo "  操作系统: $OS"
    echo "  CPU 核心: $CPU_CORES"
    echo "  内存: ${MEMORY_GB}GB"
    echo ""
    echo "🌐 访问地址:"
    echo "  前端应用: http://localhost:3000"
    echo "  后端 API: http://localhost:8080"
    echo "  API 文档: http://localhost:8080/swagger/index.html"
    echo ""
    echo "🔧 管理命令:"
    echo "  查看状态: docker-compose ps"
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo ""
    echo "📚 文档:"
    echo "  部署指南: ./DEPLOYMENT-GUIDE.md"
    echo "  架构指南: ./ARM64-DEPLOYMENT-GUIDE.md"
    echo "  故障排除: ./docs/troubleshooting.md"
}

# 主函数
main() {
    show_banner
    
    # 系统检测
    detect_system_info
    check_system_requirements
    
    # 环境准备
    configure_package_sources
    install_docker
    install_docker_compose
    configure_docker_registry
    setup_docker_buildx
    
    # 应用部署
    configure_environment
    pull_images
    build_application
    start_services
    
    # 验证部署
    if wait_for_services; then
        show_deployment_result
    else
        log_error "部署验证失败，请检查日志"
        docker-compose logs
        exit 1
    fi
}

# 执行主函数
main "$@"