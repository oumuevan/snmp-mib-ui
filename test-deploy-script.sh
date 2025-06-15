#!/bin/bash

# SNMP MIB Platform 部署脚本测试工具
# 作者: Evan
# 用于测试 deploy-china.sh 脚本的各个功能模块

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

# 测试 Docker 检测功能
test_docker_detection() {
    log_step "测试 Docker 检测功能..."
    
    # 测试 Docker 命令检测
    if command -v docker &> /dev/null; then
        log_success "Docker 命令检测: 通过"
        
        # 测试 Docker 版本获取
        if DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1); then
            log_success "Docker 版本获取: $DOCKER_VERSION"
        else
            log_error "Docker 版本获取: 失败"
        fi
        
        # 测试 Docker 服务状态
        if docker info &> /dev/null; then
            log_success "Docker 服务状态: 运行中"
        else
            log_warning "Docker 服务状态: 未运行或权限不足"
        fi
        
        # 测试 Docker 权限
        if docker ps &> /dev/null; then
            log_success "Docker 权限检查: 通过"
        else
            log_warning "Docker 权限检查: 需要 sudo 或用户组配置"
        fi
    else
        log_error "Docker 命令检测: 未安装"
    fi
}

# 测试 Docker Compose 检测功能
test_compose_detection() {
    log_step "测试 Docker Compose 检测功能..."
    
    # 测试新版本 docker compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null | head -1 | awk '{print $4}' || echo "unknown")
        log_success "Docker Compose V2 检测: $COMPOSE_VERSION"
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo "unknown")
        log_success "Docker Compose V1 检测: $COMPOSE_VERSION"
        COMPOSE_CMD="docker-compose"
    else
        log_error "Docker Compose 检测: 未安装或无法工作"
        return 1
    fi
    
    # 测试 compose 配置验证功能
    local test_compose_file="/tmp/test-compose-$$.yml"
    cat > "$test_compose_file" <<EOF
version: '3.8'
services:
  test:
    image: hello-world
    command: echo "Docker Compose test successful"
EOF
    
    if $COMPOSE_CMD -f "$test_compose_file" config &> /dev/null; then
        log_success "Docker Compose 配置验证: 通过"
    else
        log_error "Docker Compose 配置验证: 失败"
    fi
    
    rm -f "$test_compose_file"
}

# 测试系统资源检查
test_system_resources() {
    log_step "测试系统资源检查..."
    
    # 测试内存检查
    if command -v free &> /dev/null; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$MEMORY_GB" -lt 4 ]; then
            log_warning "内存检查: ${MEMORY_GB}GB (建议至少 4GB)"
        else
            log_success "内存检查: ${MEMORY_GB}GB"
        fi
    elif command -v vm_stat &> /dev/null; then
        log_info "内存检查: macOS 系统，使用 vm_stat"
        local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        if [ -n "$pages_free" ] && [ "$pages_free" -gt 0 ]; then
            local memory_mb=$((pages_free * 4096 / 1024 / 1024))
            log_success "内存检查: 约 ${memory_mb}MB 可用"
        else
            log_warning "内存检查: 无法准确检测"
        fi
    else
        log_warning "内存检查: 无法检测"
    fi
    
    # 测试磁盘空间检查
    if command -v df &> /dev/null; then
        local disk_space
        if [[ "$OSTYPE" == "darwin"* ]]; then
            disk_space=$(df -g . 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
        else
            disk_space=$(df -BG . 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
        fi
        
        if [ "${disk_space:-0}" -lt 20 ]; then
            log_warning "磁盘空间检查: ${disk_space}GB (建议至少 20GB)"
        else
            log_success "磁盘空间检查: ${disk_space}GB"
        fi
    else
        log_warning "磁盘空间检查: 无法检测"
    fi
}

# 测试网络连接
test_network_connectivity() {
    log_step "测试网络连接..."
    
    # 测试基本网络连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "网络连接: 正常"
    else
        log_warning "网络连接: 可能存在问题"
    fi
    
    # 测试 Docker Hub 连接
    if ping -c 1 registry-1.docker.io &> /dev/null; then
        log_success "Docker Hub 连接: 正常"
    else
        log_warning "Docker Hub 连接: 可能需要使用镜像源"
    fi
    
    # 测试阿里云镜像源连接
    if ping -c 1 registry.cn-hangzhou.aliyuncs.com &> /dev/null; then
        log_success "阿里云镜像源连接: 正常"
    else
        log_warning "阿里云镜像源连接: 可能存在问题"
    fi
}

# 测试必要工具
test_required_tools() {
    log_step "测试必要工具..."
    
    local tools=("curl" "openssl" "awk" "sed" "grep")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "工具检查: $tool 已安装"
        else
            log_warning "工具检查: $tool 未安装"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_warning "缺少工具: ${missing_tools[*]}"
        log_info "部分功能可能受到影响"
    else
        log_success "所有必要工具都已安装"
    fi
}

# 测试文件权限
test_file_permissions() {
    log_step "测试文件权限..."
    
    # 测试当前目录写权限
    if touch test_write_permission.tmp 2>/dev/null; then
        rm -f test_write_permission.tmp
        log_success "当前目录写权限: 正常"
    else
        log_error "当前目录写权限: 无权限"
    fi
    
    # 测试 sudo 权限（如果需要）
    if sudo -n true 2>/dev/null; then
        log_success "sudo 权限: 可用（无密码）"
    elif sudo -v 2>/dev/null; then
        log_success "sudo 权限: 可用（需要密码）"
    else
        log_warning "sudo 权限: 不可用或需要配置"
    fi
}

# 主测试函数
main() {
    echo -e "${CYAN}==================== SNMP MIB Platform 部署脚本测试 ====================${NC}"
    echo -e "${GREEN}作者: Evan${NC}"
    echo -e "${BLUE}测试 deploy-china.sh 脚本的各个功能模块${NC}"
    echo ""
    
    test_docker_detection
    echo ""
    
    test_compose_detection
    echo ""
    
    test_system_resources
    echo ""
    
    test_network_connectivity
    echo ""
    
    test_required_tools
    echo ""
    
    test_file_permissions
    echo ""
    
    echo -e "${CYAN}==================== 测试完成 ====================${NC}"
    echo -e "${GREEN}如果所有测试都通过，可以安全运行 deploy-china.sh${NC}"
    echo -e "${YELLOW}如果有警告，请根据提示进行相应配置${NC}"
    echo ""
}

# 运行测试
main "$@"