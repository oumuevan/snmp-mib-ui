#!/bin/bash

# 国内优化启动脚本 - 同时运行前端和后端服务
# 适用于容器环境

set -e

echo "🇨🇳 启动 MIB Web Platform (China Optimized)"
echo "📅 启动时间: $(date)"
echo "🖥️  主机名: $(hostname)"
echo "🔧 Node.js 版本: $(node --version)"
echo "📦 npm 版本: $(npm --version)"

# 检查环境变量
echo "🔍 检查环境变量..."
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  警告: DATABASE_URL 未设置，使用默认值"
    # 从环境变量构建数据库连接字符串
    DB_PASSWORD=${POSTGRES_PASSWORD:-"netmon_pass_2024"}
    export DATABASE_URL="postgresql://netmon_user:${DB_PASSWORD}@postgres:5432/network_monitor"
fi

if [ -z "$REDIS_URL" ]; then
    echo "⚠️  警告: REDIS_URL 未设置，使用默认值"
    # 从环境变量构建Redis连接字符串
    REDIS_PASSWORD=${REDIS_PASSWORD:-"redis_pass_2024"}
    export REDIS_URL="redis://:${REDIS_PASSWORD}@redis:6379/0"
fi

if [ -z "$JWT_SECRET" ]; then
    echo "❌ 错误: JWT_SECRET 未设置"
    exit 1
fi

# 等待数据库和 Redis 就绪
echo "⏳ 等待数据库连接..."
until curl -f "$DATABASE_URL" 2>/dev/null || nc -z postgres 5432; do
    echo "🔄 等待 PostgreSQL 启动..."
    sleep 2
done
echo "✅ PostgreSQL 连接成功"

echo "⏳ 等待 Redis 连接..."
until nc -z redis 6379; do
    echo "🔄 等待 Redis 启动..."
    sleep 2
done
echo "✅ Redis 连接成功"

# 创建日志目录
mkdir -p /app/logs

# 启动后端服务
echo "🔧 启动后端服务..."
cd /app
./backend/main > /app/logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "📋 后端进程 PID: $BACKEND_PID"

# 等待后端启动
echo "⏳ 等待后端服务启动..."
sleep 5

# 检查后端是否启动成功
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ 后端服务启动失败"
    cat /app/logs/backend.log
    exit 1
fi

# 等待后端 API 就绪
echo "🔍 检查后端 API 状态..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health 2>/dev/null; then
        echo "✅ 后端 API 就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ 后端 API 启动超时"
        cat /app/logs/backend.log
        exit 1
    fi
    echo "🔄 等待后端 API 就绪... ($i/30)"
    sleep 2
done

# 启动前端服务
echo "🌐 启动前端服务..."
node server.js > /app/logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "📋 前端进程 PID: $FRONTEND_PID"

# 等待前端启动
echo "⏳ 等待前端服务启动..."
sleep 5

# 检查前端是否启动成功
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "❌ 前端服务启动失败"
    cat /app/logs/frontend.log
    exit 1
fi

# 等待前端就绪
echo "🔍 检查前端服务状态..."
for i in {1..30}; do
    if curl -f http://localhost:3000 2>/dev/null; then
        echo "✅ 前端服务就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ 前端服务启动超时"
        cat /app/logs/frontend.log
        exit 1
    fi
    echo "🔄 等待前端服务就绪... ($i/30)"
    sleep 2
done

echo ""
echo "🎉 所有服务启动成功！"
echo "🌐 前端服务: http://localhost:3000"
echo "🔧 后端 API: http://localhost:8080"
echo "📊 健康检查: http://localhost:8080/health"
echo "📋 进程状态:"
echo "   - 前端 PID: $FRONTEND_PID"
echo "   - 后端 PID: $BACKEND_PID"
echo ""

# 监控函数
monitor_services() {
    while true; do
        # 检查后端进程
        if ! kill -0 $BACKEND_PID 2>/dev/null; then
            echo "❌ 后端服务异常退出，查看日志:"
            tail -20 /app/logs/backend.log
            exit 1
        fi
        
        # 检查前端进程
        if ! kill -0 $FRONTEND_PID 2>/dev/null; then
            echo "❌ 前端服务异常退出，查看日志:"
            tail -20 /app/logs/frontend.log
            exit 1
        fi
        
        sleep 10
    done
}

# 信号处理函数
cleanup() {
    echo ""
    echo "🛑 收到停止信号，正在优雅关闭服务..."
    
    # 停止前端服务
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "🌐 停止前端服务..."
        kill -TERM $FRONTEND_PID
        wait $FRONTEND_PID 2>/dev/null || true
    fi
    
    # 停止后端服务
    if kill -0 $BACKEND_PID 2>/dev/null; then
        echo "🔧 停止后端服务..."
        kill -TERM $BACKEND_PID
        wait $BACKEND_PID 2>/dev/null || true
    fi
    
    echo "✅ 所有服务已停止"
    exit 0
}

# 注册信号处理
trap cleanup SIGTERM SIGINT SIGQUIT

# 启动监控
echo "📡 启动服务监控..."
monitor_services &
MONITOR_PID=$!

# 等待信号
echo "🔄 服务运行中，等待停止信号..."
wait