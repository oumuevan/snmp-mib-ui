#!/bin/bash

# Multi-Architecture Startup Script
# Supports both AMD64 and ARM64 architectures

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

# 获取系统信息
ARCH=$(detect_architecture)
CPU_CORES=$(nproc)
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')

log_info "🚀 启动 MIB Web Platform (Multi-Architecture)"
log_info "架构: $ARCH"
log_info "CPU 核心数: $CPU_CORES"
log_info "内存: ${MEMORY_GB}GB"

# 架构特定优化
optimize_for_architecture() {
    case $ARCH in
        "amd64")
            log_info "应用 AMD64 架构优化"
            export NODE_OPTIONS="--max-old-space-size=4096 --optimize-for-size"
            export UV_THREADPOOL_SIZE=$((CPU_CORES * 2))
            ;;
        "arm64")
            log_info "应用 ARM64 架构优化"
            export NODE_OPTIONS="--max-old-space-size=2048 --optimize-for-size"
            export UV_THREADPOOL_SIZE=$CPU_CORES
            # ARM64 特定的 V8 优化
            export NODE_OPTIONS="$NODE_OPTIONS --experimental-wasm-simd"
            ;;
        "armv7")
            log_info "应用 ARMv7 架构优化"
            export NODE_OPTIONS="--max-old-space-size=1024 --optimize-for-size"
            export UV_THREADPOOL_SIZE=$((CPU_CORES < 4 ? CPU_CORES : 4))
            ;;
        *)
            log_warning "未知架构 $ARCH，使用默认配置"
            export NODE_OPTIONS="--max-old-space-size=2048"
            export UV_THREADPOOL_SIZE=4
            ;;
    esac
}

# 环境变量检查
check_environment() {
    log_info "检查环境变量..."
    
    # 数据库配置
    if [ -z "$DATABASE_URL" ]; then
        log_warning "DATABASE_URL 未设置，使用默认配置"
        export DATABASE_URL="postgresql://netmon_user:${POSTGRES_PASSWORD:-netmon_pass_2024}@postgres:5432/network_monitor"
    fi
    
    # Redis 配置
    if [ -z "$REDIS_URL" ]; then
        log_warning "REDIS_URL 未设置，使用默认配置"
        export REDIS_URL="redis://:${REDIS_PASSWORD:-redis_pass_2024}@redis:6379/0"
    fi
    
    # JWT 密钥检查
    if [ -z "$JWT_SECRET" ]; then
        log_error "JWT_SECRET 未设置！"
        exit 1
    fi
    
    # Session 密钥检查
    if [ -z "$SESSION_SECRET" ]; then
        log_error "SESSION_SECRET 未设置！"
        exit 1
    fi
}

# 等待数据库就绪
wait_for_database() {
    log_info "等待数据库就绪..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$DATABASE_URL" > /dev/null 2>&1; then
            log_success "数据库连接成功"
            return 0
        fi
        
        log_info "等待数据库... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "数据库连接超时"
    exit 1
}

# 等待 Redis 就绪
wait_for_redis() {
    log_info "等待 Redis 就绪..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if redis-cli -u "$REDIS_URL" ping > /dev/null 2>&1; then
            log_success "Redis 连接成功"
            return 0
        fi
        
        log_info "等待 Redis... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "Redis 连接超时"
    exit 1
}

# 创建日志目录
create_log_directories() {
    log_info "创建日志目录..."
    mkdir -p /var/log/mibweb/frontend
    mkdir -p /var/log/mibweb/backend
    mkdir -p /app/uploads
    mkdir -p /app/mibs
}

# 启动后端服务
start_backend() {
    log_info "启动后端服务..."
    cd /app
    ./backend/main > /var/log/mibweb/backend/app.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > /tmp/backend.pid
    log_success "后端服务已启动 (PID: $BACKEND_PID)"
}

# 启动前端服务
start_frontend() {
    log_info "启动前端服务..."
    cd /app
    node server.js > /var/log/mibweb/frontend/app.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > /tmp/frontend.pid
    log_success "前端服务已启动 (PID: $FRONTEND_PID)"
}

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 检查后端
    if kill -0 $BACKEND_PID 2>/dev/null; then
        log_success "后端服务运行正常"
    else
        log_error "后端服务启动失败"
        exit 1
    fi
    
    # 检查前端
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        log_success "前端服务运行正常"
    else
        log_error "前端服务启动失败"
        exit 1
    fi
}

# 等待 API 就绪
wait_for_api() {
    log_info "等待 API 服务就绪..."
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
            log_success "API 服务就绪"
            return 0
        fi
        
        log_info "等待 API 服务... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "API 服务启动超时"
    exit 1
}

# 服务监控
monitor_services() {
    log_info "开始监控服务..."
    
    while true; do
        # 检查后端进程
        if ! kill -0 $BACKEND_PID 2>/dev/null; then
            log_error "后端服务异常退出，重启中..."
            start_backend
        fi
        
        # 检查前端进程
        if ! kill -0 $FRONTEND_PID 2>/dev/null; then
            log_error "前端服务异常退出，重启中..."
            start_frontend
        fi
        
        sleep 30
    done
}

# 信号处理
cleanup() {
    log_info "正在关闭服务..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
        log_info "后端服务已关闭"
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
        log_info "前端服务已关闭"
    fi
    
    log_success "服务已安全关闭"
    exit 0
}

# 设置信号处理
trap cleanup SIGTERM SIGINT

# 主启动流程
main() {
    # 应用架构优化
    optimize_for_architecture
    
    # 检查环境变量
    check_environment
    
    # 等待依赖服务
    wait_for_database
    wait_for_redis
    
    # 创建必要目录
    create_log_directories
    
    # 启动服务
    start_backend
    start_frontend
    
    # 检查服务状态
    sleep 5
    check_services
    
    # 等待 API 就绪
    wait_for_api
    
    log_success "🎉 MIB Web Platform 启动成功！"
    log_info "前端地址: http://localhost:3000"
    log_info "后端 API: http://localhost:8080"
    log_info "架构: $ARCH"
    log_info "优化配置已应用"
    
    # 开始监控
    monitor_services
}

# 执行主函数
main "$@"