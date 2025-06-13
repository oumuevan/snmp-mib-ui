#!/bin/bash

# SNMP Web UI 一键部署脚本
# 用于快速部署项目到生产环境

set -e

echo "🚀 开始部署 SNMP Web UI..."

# 颜色输出
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

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到root用户，建议使用普通用户运行"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查系统依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        log_info "安装命令: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    # 检查Git (可选)
    if ! command -v git &> /dev/null; then
        log_warning "Git 未安装，无法从远程仓库更新代码"
    fi
    
    log_success "系统依赖检查完成"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    mkdir -p logs
    mkdir -p data/postgres
    mkdir -p data/redis
    mkdir -p nginx/ssl
    mkdir -p config/backup
    
    log_success "目录创建完成"
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    # 如果.env文件不存在，创建默认配置
    if [[ ! -f .env ]]; then
        cat > .env << EOF
# 数据库配置
POSTGRES_DB=network_monitor
POSTGRES_USER=netmon_user
POSTGRES_PASSWORD=netmon_pass_2024

# Redis配置
REDIS_PASSWORD=redis_pass_2024

# 应用配置
NODE_ENV=production
NEXTAUTH_SECRET=mibweb_secret_key_2024_very_secure
NEXTAUTH_URL=http://YOUR_SERVER_IP:3000

# JWT配置
JWT_SECRET=jwt_secret_key_2024_very_secure

# CORS配置
CORS_ORIGINS=http://localhost:3000,http://localhost

# 端口配置
FRONTEND_PORT=3000
BACKEND_PORT=8080
POSTGRES_PORT=5432
REDIS_PORT=6379
EOF
        log_success "已创建默认 .env 配置文件"
    else
        log_info "使用现有的 .env 配置文件"
    fi
}

# 构建和启动服务
deploy_services() {
    log_info "开始构建和部署服务..."
    
    # 停止现有服务
    log_info "停止现有服务..."
    docker-compose down --remove-orphans || true
    
    # 清理旧镜像 (可选)
    read -p "是否清理旧的Docker镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理旧镜像..."
        docker system prune -f || true
    fi
    
    # 构建新镜像
    log_info "构建应用镜像..."
    docker-compose build --no-cache
    
    # 启动服务
    log_info "启动服务..."
    docker-compose up -d
    
    log_success "服务部署完成"
}

# 等待服务启动
wait_for_services() {
    log_info "等待服务启动..."
    
    # 等待数据库启动
    log_info "等待数据库启动..."
    local retries=30
    while ! docker-compose exec postgres pg_isready -U netmon_user -d network_monitor > /dev/null 2>&1; do
        retries=$((retries - 1))
        if [[ $retries -eq 0 ]]; then
            log_error "数据库启动超时"
            exit 1
        fi
        sleep 2
        echo -n "."
    done
    echo
    log_success "数据库已启动"
    
    # 等待Redis启动
    log_info "等待Redis启动..."
    retries=30
    while ! docker-compose exec redis redis-cli -a redis_pass_2024 ping > /dev/null 2>&1; do
        retries=$((retries - 1))
        if [[ $retries -eq 0 ]]; then
            log_error "Redis启动超时"
            exit 1
        fi
        sleep 2
        echo -n "."
    done
    echo
    log_success "Redis已启动"
    
    # 等待前端应用启动
    log_info "等待前端应用启动..."
    retries=60
    while ! curl -f http://localhost:3000 > /dev/null 2>&1; do
        retries=$((retries - 1))
        if [[ $retries -eq 0 ]]; then
            log_error "前端应用启动超时"
            log_info "查看日志: docker-compose logs frontend"
            exit 1
        fi
        sleep 3
        echo -n "."
    done
    echo
    log_success "前端应用已启动"
}

# 显示部署信息
show_deployment_info() {
    log_success "🎉 部署完成!"
    echo
    echo "═══════════════════════════════════════"
    echo "📋 服务访问信息"
    echo "═══════════════════════════════════════"
    echo "🌐 前端应用: http://localhost:3000"
    echo "🗄️  数据库: localhost:5432"
    echo "📝 Redis: localhost:6379"
    echo
    echo "═══════════════════════════════════════"
    echo "📋 常用命令"
    echo "═══════════════════════════════════════"
    echo "查看服务状态: docker-compose ps"
    echo "查看日志: docker-compose logs -f [服务名]"
    echo "重启服务: docker-compose restart [服务名]"
    echo "停止服务: docker-compose down"
    echo "进入容器: docker-compose exec [服务名] sh"
    echo
    echo "═══════════════════════════════════════"
    echo "📋 数据库信息"
    echo "═══════════════════════════════════════"
    echo "数据库名: network_monitor"
    echo "用户名: netmon_user"
    echo "密码: netmon_pass_2024"
    echo
}

# 主函数
main() {
    echo "═══════════════════════════════════════"
    echo "🔧 SNMP Web UI 一键部署脚本"
    echo "═══════════════════════════════════════"
    echo
    
    check_root
    check_dependencies
    create_directories
    setup_environment
    deploy_services
    wait_for_services
    show_deployment_info
    
    log_success "部署脚本执行完成!"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi