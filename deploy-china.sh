#!/bin/bash

# SNMP MIB Platform 中国大陆部署脚本
# 作者: Evan
# 针对国内网络环境优化，使用国内镜像源

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

# 检查系统要求
check_requirements() {
    log_step "检查系统要求..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "操作系统: Linux"
    else
        log_warning "建议在 Linux 系统上运行"
    fi
    
    # 检查 Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker 版本: $DOCKER_VERSION"
    else
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker Compose 版本: $COMPOSE_VERSION"
    elif docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        log_success "Docker Compose 版本: $COMPOSE_VERSION"
        COMPOSE_CMD="docker compose"
    else
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    # 设置默认的 compose 命令
    COMPOSE_CMD=${COMPOSE_CMD:-"docker-compose"}
    
    # 检查可用内存
    if command -v free &> /dev/null; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$MEMORY_GB" -lt 4 ]; then
            log_warning "可用内存少于 4GB，可能影响性能"
        else
            log_success "可用内存: ${MEMORY_GB}GB"
        fi
    fi
    
    # 检查可用磁盘空间
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 20 ]; then
        log_warning "可用磁盘空间少于 20GB，可能不足"
    else
        log_success "可用磁盘空间: ${DISK_SPACE}GB"
    fi
}

# 配置国内镜像源
setup_china_mirrors() {
    log_step "配置国内镜像源..."
    
    # 配置 Docker 镜像源
    DOCKER_DAEMON_FILE="/etc/docker/daemon.json"
    if [ -f "$DOCKER_DAEMON_FILE" ]; then
        log_info "Docker daemon.json 已存在，请手动检查镜像源配置"
    else
        log_info "配置 Docker 镜像源..."
        sudo mkdir -p /etc/docker
        sudo tee $DOCKER_DAEMON_FILE > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
        sudo systemctl restart docker
        log_success "Docker 镜像源配置完成"
    fi
    
    # 配置 npm 镜像源
    if command -v npm &> /dev/null; then
        npm config set registry https://registry.npmmirror.com
        log_success "npm 镜像源配置完成"
    fi
    
    # 配置 Go 代理
    export GOPROXY=https://goproxy.cn,direct
    export GOSUMDB=sum.golang.google.cn
    log_success "Go 代理配置完成"
}

# 创建必要的目录
create_directories() {
    log_step "创建必要的目录..."
    
    mkdir -p data/postgres
    mkdir -p data/redis
    mkdir -p uploads
    mkdir -p mibs
    mkdir -p config/snmp_exporter
    mkdir -p config/categraf
    mkdir -p nginx/logs
    mkdir -p nginx/ssl
    
    # 设置权限
    chmod 755 data/postgres data/redis uploads mibs config
    
    log_success "目录创建完成"
}

# 生成环境配置文件
generate_env_file() {
    log_step "生成环境配置文件..."
    
    if [ ! -f .env ]; then
        cat > .env <<EOF
# 数据库配置
POSTGRES_DB=mib_platform
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
POSTGRES_PORT=5432

# Redis 配置
REDIS_PORT=6379

# 应用配置
BACKEND_PORT=8080
FRONTEND_PORT=3000
HTTP_PORT=80
HTTPS_PORT=443

# JWT 密钥
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# CORS 配置
CORS_ORIGINS=http://localhost:3000,http://localhost

# API 配置
NEXT_PUBLIC_API_URL=http://localhost:8080

# 环境
ENVIRONMENT=production

# 数据目录
DATA_DIR=./data
EOF
        log_success "环境配置文件生成完成"
    else
        log_info "环境配置文件已存在，跳过生成"
    fi
}

# 拉取镜像
pull_images() {
    log_step "拉取 Docker 镜像..."
    
    # 使用国内镜像源拉取基础镜像
    docker pull registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine
    docker pull registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine
    docker pull registry.cn-hangzhou.aliyuncs.com/library/nginx:alpine
    docker pull registry.cn-hangzhou.aliyuncs.com/library/golang:1.23-alpine
    docker pull registry.cn-hangzhou.aliyuncs.com/library/node:20-alpine
    
    log_success "镜像拉取完成"
}

# 构建应用镜像
build_images() {
    log_step "构建应用镜像..."
    
    # 构建后端镜像
    log_info "构建后端镜像..."
    docker build -f backend/Dockerfile.china -t snmp-mib-backend:latest ./backend
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    docker build -f Dockerfile.frontend.china -t snmp-mib-frontend:latest .
    
    log_success "应用镜像构建完成"
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    # 使用中国优化的 compose 文件
    $COMPOSE_CMD -f docker-compose.china.yml up -d
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_step "等待服务就绪..."
    
    # 等待数据库就绪
    log_info "等待数据库启动..."
    for i in {1..30}; do
        if $COMPOSE_CMD -f docker-compose.china.yml exec -T postgres pg_isready -U postgres &> /dev/null; then
            log_success "数据库已就绪"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "数据库启动超时"
            exit 1
        fi
        sleep 2
    done
    
    # 等待 Redis 就绪
    log_info "等待 Redis 启动..."
    for i in {1..30}; do
        if $COMPOSE_CMD -f docker-compose.china.yml exec -T redis redis-cli ping &> /dev/null; then
            log_success "Redis 已就绪"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "Redis 启动超时"
            exit 1
        fi
        sleep 2
    done
    
    # 等待后端就绪
    log_info "等待后端服务启动..."
    for i in {1..60}; do
        if curl -f http://localhost:8080/health &> /dev/null; then
            log_success "后端服务已就绪"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "后端服务启动超时"
            exit 1
        fi
        sleep 3
    done
    
    # 等待前端就绪
    log_info "等待前端服务启动..."
    for i in {1..60}; do
        if curl -f http://localhost:3000 &> /dev/null; then
            log_success "前端服务已就绪"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "前端服务启动超时"
            exit 1
        fi
        sleep 3
    done
}

# 显示部署信息
show_deployment_info() {
    log_step "部署完成！"
    
    echo ""
    echo -e "${CYAN}==================== 部署信息 ====================${NC}"
    echo -e "${GREEN}✅ SNMP MIB Platform 部署成功！${NC}"
    echo ""
    echo -e "${YELLOW}访问地址:${NC}"
    echo -e "  🌐 前端界面: ${BLUE}http://localhost:3000${NC}"
    echo -e "  🔧 后端 API: ${BLUE}http://localhost:8080${NC}"
    echo -e "  📊 健康检查: ${BLUE}http://localhost:8080/health${NC}"
    echo ""
    echo -e "${YELLOW}管理命令:${NC}"
    echo -e "  查看服务状态: ${BLUE}$COMPOSE_CMD -f docker-compose.china.yml ps${NC}"
    echo -e "  查看日志: ${BLUE}$COMPOSE_CMD -f docker-compose.china.yml logs -f${NC}"
    echo -e "  停止服务: ${BLUE}$COMPOSE_CMD -f docker-compose.china.yml down${NC}"
    echo -e "  重启服务: ${BLUE}$COMPOSE_CMD -f docker-compose.china.yml restart${NC}"
    echo ""
    echo -e "${YELLOW}数据目录:${NC}"
    echo -e "  PostgreSQL: ${BLUE}./data/postgres${NC}"
    echo -e "  Redis: ${BLUE}./data/redis${NC}"
    echo -e "  上传文件: ${BLUE}./uploads${NC}"
    echo -e "  MIB 文件: ${BLUE}./mibs${NC}"
    echo ""
    echo -e "${YELLOW}配置文件:${NC}"
    echo -e "  环境变量: ${BLUE}.env${NC}"
    echo -e "  Nginx 配置: ${BLUE}nginx/nginx.china.conf${NC}"
    echo -e "  Redis 配置: ${BLUE}redis/redis.conf${NC}"
    echo ""
    echo -e "${GREEN}🎉 开始使用 SNMP MIB Platform 吧！${NC}"
    echo -e "${CYAN}=================================================${NC}"
}

# 清理函数
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "部署失败，正在清理..."
        $COMPOSE_CMD -f docker-compose.china.yml down 2>/dev/null || true
    fi
}

# 主函数
main() {
    echo -e "${CYAN}"
    echo "================================================="
    echo "    SNMP MIB Platform 中国大陆部署脚本"
    echo "    针对国内网络环境优化"
    echo "================================================="
    echo -e "${NC}"
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 检查是否为 root 用户
    if [ "$EUID" -eq 0 ]; then
        log_warning "不建议使用 root 用户运行此脚本"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 执行部署步骤
    check_requirements
    setup_china_mirrors
    create_directories
    generate_env_file
    pull_images
    build_images
    start_services
    wait_for_services
    show_deployment_info
    
    # 移除清理陷阱
    trap - EXIT
}

# 处理命令行参数
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  help, -h, --help    显示此帮助信息"
        echo "  clean               清理所有容器和数据"
        echo "  restart             重启所有服务"
        echo "  logs                查看服务日志"
        echo "  status              查看服务状态"
        echo ""
        echo "示例:"
        echo "  $0                  执行完整部署"
        echo "  $0 clean            清理环境"
        echo "  $0 restart          重启服务"
        exit 0
        ;;
    "clean")
        log_step "清理环境..."
        $COMPOSE_CMD -f docker-compose.china.yml down -v --remove-orphans
        docker system prune -f
        log_success "环境清理完成"
        exit 0
        ;;
    "restart")
        log_step "重启服务..."
        $COMPOSE_CMD -f docker-compose.china.yml restart
        log_success "服务重启完成"
        exit 0
        ;;
    "logs")
        $COMPOSE_CMD -f docker-compose.china.yml logs -f
        exit 0
        ;;
    "status")
        $COMPOSE_CMD -f docker-compose.china.yml ps
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "未知选项: $1"
        echo "使用 '$0 help' 查看帮助信息"
        exit 1
        ;;
esac