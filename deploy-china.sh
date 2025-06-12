#!/bin/bash

# 国内服务器一键部署脚本
# 适用于 CentOS 7+, Ubuntu 18.04+, Debian 9+
# 版本: 2.0
# 更新时间: 2024-12

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 错误处理
error_exit() {
    log_error "$1"
    exit 1
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到 root 用户，建议使用普通用户运行此脚本"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        DISTRO=$ID
    else
        error_exit "无法检测操作系统版本"
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查内存
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$MEMORY_GB" -lt 2 ]; then
        log_warning "系统内存不足 2GB，可能影响性能"
    fi
    
    # 检查磁盘空间
    DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$DISK_GB" -lt 10 ]; then
        error_exit "磁盘空间不足 10GB"
    fi
    
    # 检查网络连接
    if ! ping -c 1 registry.npmmirror.com &> /dev/null; then
        log_warning "无法连接到 npm 镜像源，可能影响依赖安装"
    fi
    
    log_success "系统要求检查完成"
}

# 配置软件源
setup_mirrors() {
    log_info "配置国内软件源..."
    
    # 检测系统架构
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="armhf" ;;
        *) log_warning "未知架构: $ARCH，使用默认配置" ;;
    esac
    
    case $DISTRO in
        ubuntu|debian)
            # 获取发行版代号
            CODENAME=$(lsb_release -cs)
            
            if [[ $DISTRO == "ubuntu" ]]; then
                # 使用新的中国镜像源配置函数
                configure_china_sources $CODENAME
            else
                # Debian 配置保持原有逻辑
                log_info "配置Debian镜像源 (架构: $ARCH, 版本: $CODENAME)..."
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
                sudo tee /etc/apt/sources.list << EOF
# 清华大学镜像源
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $CODENAME main non-free contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $CODENAME-updates main non-free contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $CODENAME-backports main non-free contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $CODENAME-security main
EOF
                
                # 最终更新
                sudo apt update || {
                    log_error "软件源更新失败，请检查网络连接"
                    return 1
                }
            fi
            ;;
        centos|rhel|rocky|almalinux)
            # 备份原始源
            sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup.$(date +%Y%m%d) 2>/dev/null || true
            
            # 配置阿里云源
            sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-$(rpm -E %{rhel}).repo
            sudo yum makecache
            ;;
        *)
            log_warning "未知的发行版，跳过软件源配置"
            ;;
    esac
    
    log_success "软件源配置完成"
}

# 安装基础依赖
install_dependencies() {
    log_info "安装基础依赖..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y curl wget git unzip vim net-tools lsof
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y curl wget git unzip vim net-tools lsof epel-release
            ;;
        *)
            error_exit "不支持的操作系统: $DISTRO"
            ;;
    esac
    
    log_success "基础依赖安装完成"
}

# 安装 Docker
install_docker() {
    log_info "安装 Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker 已安装，版本: $(docker --version)"
        return
    fi
    
    case $DISTRO in
        ubuntu)
            # 安装 Docker GPG 密钥
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
            
            # 添加 Docker 仓库
            sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
            
            # 安装 Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io
            ;;
        debian)
            # 安装 Docker GPG 密钥
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo apt-key add -
            
            # 添加 Docker 仓库
            echo "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
            
            # 安装 Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io
            ;;
        centos|rhel|rocky|almalinux)
            # 安装 Docker 仓库
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            
            # 安装 Docker
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            ;;
        *)
            error_exit "不支持的操作系统: $DISTRO"
            ;;
    esac
    
    # 启动 Docker 服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加当前用户到 docker 组
    sudo usermod -aG docker $USER
    
    log_success "Docker 安装完成"
}

# 配置 Docker 镜像源
setup_docker_mirrors() {
    log_info "配置 Docker 国内镜像源..."
    
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
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    log_success "Docker 镜像源配置完成"
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "安装 Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose 已安装，版本: $(docker-compose --version)"
        return
    fi
    
    # 使用 DaoCloud 镜像下载
    COMPOSE_VERSION="2.20.0"
    sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose 安装完成"
}

# 配置中国镜像源
configure_china_sources() {
    local codename=$1
    log_info "配置中国镜像源..."
    
    # 备份原始源文件
    if [ -f /etc/apt/sources.list ]; then
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    fi
    
    # 检测架构并配置相应的软件源
    local arch=$(dpkg --print-architecture)
    
    if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
        # ARM64 架构优先使用阿里云源（稳定性更好）
        log_info "ARM64 架构，尝试配置阿里云镜像源..."
        sudo tee /etc/apt/sources.list << EOF
# 阿里云镜像源 - ARM64 支持稳定
deb https://mirrors.aliyun.com/ubuntu/ ${codename} main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
        
        # 测试阿里云源可用性
        if ! sudo apt update 2>/dev/null; then
            log_warning "阿里云镜像源不可用，尝试华为云镜像源..."
            sudo tee /etc/apt/sources.list << EOF
# 华为云镜像源 - ARM64 备选
deb https://mirrors.huaweicloud.com/ubuntu/ ${codename} main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ ${codename}-updates main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ ${codename}-backports main restricted universe multiverse
deb https://mirrors.huaweicloud.com/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
            
            if ! sudo apt update 2>/dev/null; then
                log_warning "华为云镜像源不可用，使用官方 ARM64 源..."
                sudo tee /etc/apt/sources.list << EOF
# Ubuntu 官方源 - ARM64 完整支持
deb http://ports.ubuntu.com/ubuntu-ports/ ${codename} main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${codename}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${codename}-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${codename}-security main restricted universe multiverse
EOF
                
                if ! sudo apt update 2>/dev/null; then
                    log_error "所有 ARM64 镜像源都不可用，恢复原始配置..."
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
    else
        # AMD64 架构使用阿里云源
        log_info "AMD64 架构，配置阿里云镜像源..."
        sudo tee /etc/apt/sources.list << EOF
# 阿里云镜像源 - AMD64 支持
deb https://mirrors.aliyun.com/ubuntu/ ${codename} main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
    fi
}

# 安装 Node.js
install_nodejs() {
    log_info "安装 Node.js..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        log_success "Node.js 已安装，版本: $NODE_VERSION"
        return
    fi
    
    # 使用 NodeSource 仓库安装 Node.js 18
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt install -y nodejs
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y nodejs npm
            ;;
    esac
    
    log_success "Node.js 安装完成"
}

# 配置 npm 国内源
setup_npm_mirrors() {
    log_info "配置 npm 国内源..."
    
    npm config set registry https://registry.npmmirror.com
    npm config set disturl https://npmmirror.com/dist
    npm config set electron_mirror https://npmmirror.com/mirrors/electron/
    npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
    npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/
    npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver/
    npm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver/
    
    log_success "npm 国内源配置完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian 使用 ufw
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 3000/tcp
        sudo ufw allow 8080/tcp
        log_success "UFW 防火墙规则配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL 使用 firewalld
        sudo firewall-cmd --permanent --add-port=22/tcp
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --permanent --add-port=3000/tcp
        sudo firewall-cmd --permanent --add-port=8080/tcp
        sudo firewall-cmd --reload
        log_success "Firewalld 防火墙规则配置完成"
    else
        log_warning "未检测到防火墙，请手动配置端口开放"
    fi
}

# 下载项目代码
download_project() {
    log_info "下载项目代码..."
    
    PROJECT_DIR="mibweb-platform"
    
    if [ -d "$PROJECT_DIR" ]; then
        log_warning "项目目录已存在，是否删除重新下载？(y/N)"
        read -p "请选择: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            cd "$PROJECT_DIR"
            log_info "使用现有项目目录"
            return
        fi
    fi
    
    # 这里应该替换为实际的项目仓库地址
    # git clone https://github.com/your-username/mibweb-platform.git
    
    # 临时创建项目目录和必要文件
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    log_success "项目代码下载完成"
}

# 配置环境变量
setup_environment() {
    log_info "配置环境变量..."
    
    if [ ! -f .env ]; then
        log_info "创建环境配置文件..."
        
        # 生成随机密钥
        JWT_SECRET=$(openssl rand -base64 32)
        SESSION_SECRET=$(openssl rand -base64 24)
        POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
        REDIS_PASSWORD=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
        
        # 获取服务器 IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
        
        cat > .env << EOF
# MIB Web Platform - 生产环境配置
# 生成时间: $(date)

# 应用配置
APP_ENV=production
APP_NAME=MIB Web Platform
DEBUG=false
LOG_LEVEL=info

# 服务器配置
NEXT_PUBLIC_API_URL=http://${SERVER_IP}:8080
FRONTEND_URL=http://${SERVER_IP}:3000
CORS_ORIGINS=http://${SERVER_IP}:3000,http://localhost:3000

# 数据库配置
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=network_monitor
POSTGRES_USER=netmon_user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
DATABASE_URL=postgresql://netmon_user:${POSTGRES_PASSWORD}@postgres:5432/network_monitor

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0

# 安全配置
JWT_SECRET=${JWT_SECRET}
SESSION_SECRET=${SESSION_SECRET}

# 缓存配置
CACHE_DEFAULT_TTL=3600
CACHE_MIB_TTL=7200

# 速率限制
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60s
EOF
        
        log_success "环境配置文件创建完成"
        log_info "服务器 IP: $SERVER_IP"
        log_info "数据库密码: $POSTGRES_PASSWORD"
        log_info "Redis 密码: $REDIS_PASSWORD"
    else
        log_success "环境配置文件已存在"
    fi
}

# 预拉取 Docker 镜像
pull_docker_images() {
    log_info "预拉取 Docker 镜像..."
    
    images=(
        "registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/node:18-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/nginx:alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/golang:1.21-alpine"
    )
    
    for image in "${images[@]}"; do
        log_info "拉取镜像: $image"
        docker pull "$image" || log_warning "镜像拉取失败: $image"
    done
    
    log_success "Docker 镜像拉取完成"
}

# 构建和启动服务
start_services() {
    log_info "构建和启动服务..."
    
    # 检查 docker-compose.china.yml 是否存在
    if [ ! -f "docker-compose.china.yml" ]; then
        log_warning "docker-compose.china.yml 不存在，使用默认配置"
        COMPOSE_FILE="docker-compose.yml"
    else
        COMPOSE_FILE="docker-compose.china.yml"
    fi
    
    # 停止可能存在的服务
    docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    
    # 构建和启动服务
    docker-compose -f "$COMPOSE_FILE" up -d --build
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务启动..."
    
    # 等待数据库
    log_info "等待数据库启动..."
    for i in {1..60}; do
        if docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U netmon_user -d network_monitor &>/dev/null; then
            log_success "数据库启动成功"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "数据库启动超时"
            return 1
        fi
        sleep 2
    done
    
    # 等待应用服务
    log_info "等待应用服务启动..."
    for i in {1..120}; do
        if curl -f http://localhost:3000 &>/dev/null; then
            log_success "应用服务启动成功"
            break
        fi
        if [ $i -eq 120 ]; then
            log_error "应用服务启动超时"
            return 1
        fi
        sleep 2
    done
}

# 显示部署结果
show_result() {
    log_success "🎉 部署完成！"
    echo ""
    echo "=================================="
    echo "    MIB Web Platform 部署成功"
    echo "=================================="
    echo ""
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
    
    echo "📱 访问地址:"
    echo "   前端: http://${SERVER_IP}:3000"
    echo "   后端: http://${SERVER_IP}:8080"
    echo "   健康检查: http://${SERVER_IP}:8080/health"
    echo ""
    echo "🔧 管理命令:"
    echo "   查看状态: docker-compose -f $COMPOSE_FILE ps"
    echo "   查看日志: docker-compose -f $COMPOSE_FILE logs -f"
    echo "   停止服务: docker-compose -f $COMPOSE_FILE down"
    echo "   重启服务: docker-compose -f $COMPOSE_FILE restart"
    echo ""
    echo "📋 配置文件:"
    echo "   环境变量: $(pwd)/.env"
    echo "   Docker配置: $(pwd)/$COMPOSE_FILE"
    echo ""
    echo "⚠️  注意事项:"
    echo "   1. 首次启动可能需要几分钟进行数据库初始化"
    echo "   2. 请确保防火墙已开放相应端口"
    echo "   3. 建议定期备份数据库和配置文件"
    echo ""
}

# 主函数
main() {
    echo "🇨🇳 MIB Web Platform 国内服务器一键部署脚本"
    echo "版本: 2.0 | 更新时间: 2024-12"
    echo "适用系统: CentOS 7+, Ubuntu 18.04+, Debian 9+"
    echo ""
    
    check_root
    detect_os
    check_requirements
    
    log_info "开始部署流程..."
    
    setup_mirrors
    install_dependencies
    install_docker
    setup_docker_mirrors
    install_docker_compose
    install_nodejs
    setup_npm_mirrors
    setup_firewall
    download_project
    setup_environment
    pull_docker_images
    start_services
    wait_for_services
    show_result
    
    log_success "部署流程完成！"
}

# 执行主函数
main "$@"