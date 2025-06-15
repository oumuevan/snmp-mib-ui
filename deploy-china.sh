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

# 检查 Docker 服务状态
check_docker_service() {
    log_info "检查 Docker 服务状态..."
    
    # 检查 Docker 守护进程是否运行
    if ! docker info &> /dev/null; then
        log_warning "Docker 守护进程未运行，尝试启动..."
        
        # 尝试启动 Docker 服务
        if command -v systemctl &> /dev/null; then
            if sudo systemctl start docker &> /dev/null; then
                log_info "使用 systemctl 启动 Docker 服务"
                sleep 5
            else
                log_error "systemctl 启动 Docker 失败"
            fi
        elif command -v service &> /dev/null; then
            if sudo service docker start &> /dev/null; then
                log_info "使用 service 启动 Docker 服务"
                sleep 5
            else
                log_error "service 启动 Docker 失败"
            fi
        else
            log_error "无法找到服务管理工具，请手动启动 Docker"
            exit 1
        fi
        
        # 再次检查 Docker 服务
        local retry_count=0
        while [ $retry_count -lt 10 ]; do
            if docker info &> /dev/null; then
                log_success "Docker 服务启动成功"
                return 0
            fi
            log_info "等待 Docker 服务启动... ($((retry_count + 1))/10)"
            sleep 2
            ((retry_count++))
        done
        
        log_error "Docker 服务启动失败，请检查："
        log_error "  1. Docker 是否正确安装"
        log_error "  2. 当前用户是否有权限"
        log_error "  3. 系统服务是否正常"
        exit 1
    fi
    
    log_success "Docker 服务运行正常"
}

# 严格的 Docker Compose 版本检测
detect_compose_command() {
    log_info "检测 Docker Compose 命令..."
    
    # 优先检查新版本的 docker compose
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null | head -1 | awk '{print $4}' || echo "unknown")
        log_success "使用 Docker Compose V2: $COMPOSE_VERSION"
        return 0
    fi
    
    # 检查旧版本的 docker-compose
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo "unknown")
        log_success "使用 Docker Compose V1: $COMPOSE_VERSION"
        return 0
    fi
    
    log_error "Docker Compose 未安装或无法正常工作"
    log_error ""
    log_error "请安装 Docker Compose："
    log_error "  Ubuntu/Debian: sudo apt-get install docker-compose-plugin"
    log_error "  CentOS/RHEL: sudo yum install docker-compose-plugin"
    log_error "  手动安装: https://docs.docker.com/compose/install/"
    log_error ""
    log_error "或者使用 pip 安装旧版本："
    log_error "  pip install docker-compose"
    exit 1
}

# 验证 Docker Compose 功能
verify_compose_functionality() {
    log_info "验证 Docker Compose 功能..."
    
    # 创建临时测试文件
    local test_compose_file="/tmp/test-compose-$$.yml"
    cat > "$test_compose_file" <<EOF
version: '3.8'
services:
  test:
    image: hello-world
    command: echo "Docker Compose test successful"
EOF
    
    # 测试 compose 配置验证
    if ! $COMPOSE_CMD -f "$test_compose_file" config &> /dev/null; then
        log_error "Docker Compose 配置验证失败"
        log_error "请检查 Docker Compose 安装是否正确"
        rm -f "$test_compose_file"
        exit 1
    fi
    
    # 清理测试文件
    rm -f "$test_compose_file"
    log_success "Docker Compose 功能验证通过"
}

# 检查系统要求
check_requirements() {
    log_step "检查系统要求..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "操作系统: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "操作系统: macOS"
    else
        log_warning "未测试的操作系统: $OSTYPE，建议在 Linux 系统上运行"
    fi
    
    # 检查 Docker 安装
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        log_error ""
        log_error "请先安装 Docker："
        log_error "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
        log_error "  CentOS/RHEL: curl -fsSL https://get.docker.com | sh"
        log_error "  官方文档: https://docs.docker.com/engine/install/"
        log_error ""
        exit 1
    fi
    
    # 获取 Docker 版本（更安全的方式）
    if DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1); then
        log_success "Docker 版本: $DOCKER_VERSION"
    else
        log_error "无法获取 Docker 版本，请检查 Docker 安装"
        exit 1
    fi
    
    # 检查 Docker 服务状态
    check_docker_service
    
    # 检测 Docker Compose 命令
    detect_compose_command
    
    # 验证 Docker Compose 功能
    verify_compose_functionality
    
    # 检查用户权限
    if ! docker ps &> /dev/null; then
        log_warning "当前用户可能没有 Docker 权限"
        log_info "如果遇到权限问题，请运行："
        log_info "  sudo usermod -aG docker \$USER"
        log_info "  然后重新登录或运行: newgrp docker"
        
        # 尝试使用 sudo 测试
        if sudo docker ps &> /dev/null; then
            log_warning "需要 sudo 权限运行 Docker，建议配置用户权限"
        else
            log_error "即使使用 sudo 也无法运行 Docker，请检查安装"
            exit 1
        fi
    fi
    
    # 检查可用内存
    if command -v free &> /dev/null; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$MEMORY_GB" -lt 4 ]; then
            log_warning "可用内存少于 4GB (当前: ${MEMORY_GB}GB)，可能影响性能"
            log_info "建议至少 8GB 内存以获得最佳性能"
        else
            log_success "可用内存: ${MEMORY_GB}GB"
        fi
    elif command -v vm_stat &> /dev/null; then
        # macOS 内存检查
        local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        if [ -n "$pages_free" ] && [ "$pages_free" -gt 0 ]; then
            local memory_mb=$((pages_free * 4096 / 1024 / 1024))
            if [ "$memory_mb" -lt 4096 ]; then
                log_warning "可用内存可能不足 (约 ${memory_mb}MB)，建议至少 4GB"
            else
                log_success "内存检查通过 (约 ${memory_mb}MB 可用)"
            fi
        else
            log_info "无法准确检测内存，请确保至少有 4GB 可用内存"
        fi
    else
        log_info "无法检测内存大小，请确保至少有 4GB 可用内存"
    fi
    
    # 检查可用磁盘空间
    if command -v df &> /dev/null; then
        local disk_space
        if [[ "$OSTYPE" == "darwin"* ]]; then
            disk_space=$(df -g . 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
        else
            disk_space=$(df -BG . 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
        fi
        
        if [ "${disk_space:-0}" -lt 20 ]; then
            log_warning "可用磁盘空间少于 20GB (当前: ${disk_space}GB)"
            log_info "建议至少 50GB 磁盘空间以存储镜像和数据"
        else
            log_success "可用磁盘空间: ${disk_space}GB"
        fi
    else
        log_info "无法检测磁盘空间，请确保至少有 20GB 可用空间"
    fi
    
    log_success "系统要求检查完成"
}

# 配置国内镜像源
setup_china_mirrors() {
    log_step "配置国内镜像源..."
    
    # 配置 Docker 镜像源
    DOCKER_DAEMON_FILE="/etc/docker/daemon.json"
    if [ -f "$DOCKER_DAEMON_FILE" ]; then
        log_info "Docker daemon.json 已存在，检查镜像源配置..."
        if grep -q "registry-mirrors" "$DOCKER_DAEMON_FILE"; then
            log_success "Docker 镜像源已配置"
        else
            log_warning "Docker daemon.json 存在但未配置镜像源"
            log_info "请手动添加镜像源配置或删除该文件重新运行脚本"
        fi
    else
        log_info "配置 Docker 镜像源..."
        if sudo mkdir -p /etc/docker; then
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
            log_success "Docker 配置文件创建成功"
            
            # 重启 Docker 服务并验证
            log_info "重启 Docker 服务以应用配置..."
            if command -v systemctl &> /dev/null; then
                if sudo systemctl restart docker; then
                    log_info "Docker 服务重启成功"
                else
                    log_error "Docker 服务重启失败"
                    exit 1
                fi
            elif command -v service &> /dev/null; then
                if sudo service docker restart; then
                    log_info "Docker 服务重启成功"
                else
                    log_error "Docker 服务重启失败"
                    exit 1
                fi
            fi
            
            # 等待 Docker 服务完全启动
            log_info "等待 Docker 服务完全启动..."
            local retry_count=0
            while [ $retry_count -lt 15 ]; do
                if docker info &> /dev/null; then
                    log_success "Docker 服务重启完成，镜像源配置生效"
                    break
                fi
                log_info "等待 Docker 服务启动... ($((retry_count + 1))/15)"
                sleep 2
                ((retry_count++))
            done
            
            if [ $retry_count -eq 15 ]; then
                log_error "Docker 服务重启后无法正常工作"
                log_error "请检查配置文件: $DOCKER_DAEMON_FILE"
                exit 1
            fi
        else
            log_error "无法创建 Docker 配置目录，请检查权限"
            exit 1
        fi
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
    
    # 定义镜像列表
    local images=(
        "registry.cn-hangzhou.aliyuncs.com/library/postgres:15-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/redis:7-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/nginx:alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/golang:1.23-alpine"
        "registry.cn-hangzhou.aliyuncs.com/library/node:20-alpine"
    )
    
    # 逐个拉取镜像并验证
    for image in "${images[@]}"; do
        log_info "拉取镜像: $image"
        local retry_count=0
        while [ $retry_count -lt 3 ]; do
            if docker pull "$image"; then
                log_success "镜像拉取成功: $image"
                break
            else
                ((retry_count++))
                if [ $retry_count -lt 3 ]; then
                    log_warning "镜像拉取失败，重试 ($retry_count/3): $image"
                    sleep 5
                else
                    log_error "镜像拉取失败，已重试 3 次: $image"
                    log_error "请检查网络连接或镜像源配置"
                    exit 1
                fi
            fi
        done
    done
    
    log_success "所有镜像拉取完成"
}

# 构建应用镜像
build_images() {
    log_step "构建应用镜像..."
    
    # 构建后端镜像
    log_info "构建后端镜像..."
    if docker build -f backend/Dockerfile.china -t snmp-mib-backend:latest ./backend; then
        log_success "后端镜像构建成功"
    else
        log_error "后端镜像构建失败"
        log_error "请检查 backend/Dockerfile.china 文件和网络连接"
        exit 1
    fi
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    if docker build -f Dockerfile.frontend.china -t snmp-mib-frontend:latest .; then
        log_success "前端镜像构建成功"
    else
        log_error "前端镜像构建失败"
        log_error "请检查 Dockerfile.frontend.china 文件和网络连接"
        exit 1
    fi
    
    # 验证镜像是否成功创建
    log_info "验证构建的镜像..."
    if docker images snmp-mib-backend:latest --format "table {{.Repository}}:{{.Tag}}" | grep -q "snmp-mib-backend:latest"; then
        log_success "后端镜像验证通过"
    else
        log_error "后端镜像验证失败"
        exit 1
    fi
    
    if docker images snmp-mib-frontend:latest --format "table {{.Repository}}:{{.Tag}}" | grep -q "snmp-mib-frontend:latest"; then
        log_success "前端镜像验证通过"
    else
        log_error "前端镜像验证失败"
        exit 1
    fi
    
    log_success "所有应用镜像构建完成"
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    # 检查 compose 文件是否存在
    if [ ! -f "docker-compose.china.yml" ]; then
        log_error "docker-compose.china.yml 文件不存在"
        exit 1
    fi
    
    # 验证 compose 文件语法
    log_info "验证 Docker Compose 配置..."
    if ! $COMPOSE_CMD -f docker-compose.china.yml config &> /dev/null; then
        log_error "Docker Compose 配置文件语法错误"
        log_error "请检查 docker-compose.china.yml 文件"
        exit 1
    fi
    
    # 停止可能存在的旧服务
    log_info "停止可能存在的旧服务..."
    $COMPOSE_CMD -f docker-compose.china.yml down &> /dev/null || true
    
    # 启动服务
    log_info "启动所有服务..."
    if $COMPOSE_CMD -f docker-compose.china.yml up -d; then
        log_success "服务启动命令执行成功"
    else
        log_error "服务启动失败"
        log_error "请检查 Docker Compose 配置和镜像"
        exit 1
    fi
    
    # 等待容器启动
    log_info "等待容器启动..."
    sleep 10
    
    # 检查服务状态
    log_info "检查服务状态..."
    local failed_services=()
    
    # 检查各个服务的状态
    if ! $COMPOSE_CMD -f docker-compose.china.yml ps postgres | grep -q "Up"; then
        failed_services+=("postgres")
    fi
    
    if ! $COMPOSE_CMD -f docker-compose.china.yml ps redis | grep -q "Up"; then
        failed_services+=("redis")
    fi
    
    if ! $COMPOSE_CMD -f docker-compose.china.yml ps backend | grep -q "Up"; then
        failed_services+=("backend")
    fi
    
    if ! $COMPOSE_CMD -f docker-compose.china.yml ps frontend | grep -q "Up"; then
        failed_services+=("frontend")
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "以下服务启动失败: ${failed_services[*]}"
        log_error "查看服务日志:"
        for service in "${failed_services[@]}"; do
            log_error "  $COMPOSE_CMD -f docker-compose.china.yml logs $service"
        done
        exit 1
    fi
    
    log_success "所有服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_step "等待服务就绪..."
    
    # 检查 curl 是否可用
    if ! command -v curl &> /dev/null; then
        log_warning "curl 未安装，将跳过 HTTP 健康检查"
        log_info "请手动验证服务是否正常运行"
    fi
    
    # 等待数据库就绪
    log_info "等待数据库启动..."
    local db_ready=false
    for i in {1..30}; do
        if $COMPOSE_CMD -f docker-compose.china.yml exec -T postgres pg_isready -U postgres &> /dev/null; then
            log_success "数据库已就绪"
            db_ready=true
            break
        fi
        log_info "等待数据库启动... ($i/30)"
        sleep 2
    done
    
    if [ "$db_ready" = false ]; then
        log_error "数据库启动超时"
        log_error "请检查数据库日志: $COMPOSE_CMD -f docker-compose.china.yml logs postgres"
        exit 1
    fi
    
    # 等待 Redis 就绪
    log_info "等待 Redis 启动..."
    local redis_ready=false
    for i in {1..30}; do
        if $COMPOSE_CMD -f docker-compose.china.yml exec -T redis redis-cli ping &> /dev/null; then
            log_success "Redis 已就绪"
            redis_ready=true
            break
        fi
        log_info "等待 Redis 启动... ($i/30)"
        sleep 2
    done
    
    if [ "$redis_ready" = false ]; then
        log_error "Redis 启动超时"
        log_error "请检查 Redis 日志: $COMPOSE_CMD -f docker-compose.china.yml logs redis"
        exit 1
    fi
    
    # 等待后端就绪
    log_info "等待后端服务启动..."
    local backend_ready=false
    for i in {1..60}; do
        if command -v curl &> /dev/null; then
            if curl -f -s --connect-timeout 5 http://localhost:8080/health &> /dev/null; then
                log_success "后端服务已就绪"
                backend_ready=true
                break
            fi
        else
            # 如果没有 curl，检查端口是否开放
            if nc -z localhost 8080 &> /dev/null || netstat -an | grep -q ":8080.*LISTEN" &> /dev/null; then
                log_success "后端服务端口已开放"
                backend_ready=true
                break
            fi
        fi
        log_info "等待后端服务启动... ($i/60)"
        sleep 3
    done
    
    if [ "$backend_ready" = false ]; then
        log_error "后端服务启动超时"
        log_error "请检查后端日志: $COMPOSE_CMD -f docker-compose.china.yml logs backend"
        exit 1
    fi
    
    # 等待前端就绪
    log_info "等待前端服务启动..."
    local frontend_ready=false
    for i in {1..60}; do
        if command -v curl &> /dev/null; then
            if curl -f -s --connect-timeout 5 http://localhost:3000 &> /dev/null; then
                log_success "前端服务已就绪"
                frontend_ready=true
                break
            fi
        else
            # 如果没有 curl，检查端口是否开放
            if nc -z localhost 3000 &> /dev/null || netstat -an | grep -q ":3000.*LISTEN" &> /dev/null; then
                log_success "前端服务端口已开放"
                frontend_ready=true
                break
            fi
        fi
        log_info "等待前端服务启动... ($i/60)"
        sleep 3
    done
    
    if [ "$frontend_ready" = false ]; then
        log_error "前端服务启动超时"
        log_error "请检查前端日志: $COMPOSE_CMD -f docker-compose.china.yml logs frontend"
        exit 1
    fi
    
    # 最终验证所有服务状态
    log_info "最终验证服务状态..."
    local all_services_up=true
    
    if ! $COMPOSE_CMD -f docker-compose.china.yml ps --format "table {{.Service}}\t{{.State}}" | grep -v "Service" | grep -q "Up"; then
        log_warning "部分服务可能未正常运行"
        all_services_up=false
    fi
    
    if [ "$all_services_up" = true ]; then
        log_success "所有服务已就绪并正常运行"
    else
        log_warning "部分服务状态异常，请检查服务日志"
        log_info "查看所有服务状态: $COMPOSE_CMD -f docker-compose.china.yml ps"
    fi
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