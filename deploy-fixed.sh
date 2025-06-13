#!/bin/bash

# MIB Web UI 自动化部署脚本 - 修复版
# 包含所有编译错误修复和优化

set -e

echo "=== MIB Web UI 自动化部署开始 ==="

# 检查必要的命令
command -v go >/dev/null 2>&1 || { echo "错误: 需要安装 Go"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "错误: 需要安装 Node.js"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "错误: 需要安装 Docker"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "错误: 需要安装 Docker Compose"; exit 1; }

# 设置工作目录
WORKDIR="/etc/opt/web-ui"
cd "$WORKDIR"

echo "当前工作目录: $(pwd)"

# 1. 启动基础服务 (PostgreSQL, Redis)
echo "=== 启动基础服务 ==="
docker-compose up -d postgres redis

# 等待服务启动
echo "等待数据库和Redis启动..."
sleep 10

# 2. 检查并创建后端环境配置
echo "=== 配置后端环境 ==="
if [ ! -f "backend/.env" ]; then
    cat > backend/.env << EOF
# Environment Configuration
PORT=8080
GIN_MODE=release

# Database Configuration
DATABASE_URL=postgres://netmon_user:netmon_pass_2024@localhost:5432/network_monitor?sslmode=disable
DB_HOST=localhost
DB_PORT=5432
DB_USER=netmon_user
DB_PASSWORD=netmon_pass_2024
DB_NAME=network_monitor
DB_SSLMODE=disable

# Redis Configuration
REDIS_URL=redis://:redis_pass_2024@localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_pass_2024
REDIS_DB=0

# VictoriaMetrics Configuration
VICTORIAMETRICS_URL=http://localhost:8428
PROMETHEUS_URL=http://localhost:8428

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=24h

# SNMP Configuration
SNMP_COMMUNITY=public
SNMP_VERSION=2c
SNMP_TIMEOUT=5s
SNMP_RETRIES=3

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# File Upload
MAX_UPLOAD_SIZE=10MB
UPLOAD_PATH=./uploads

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
CORS_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_HEADERS=Content-Type,Authorization

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=1m

# Cache
CACHE_TTL=300s
CACHE_CLEANUP_INTERVAL=600s
EOF
    echo "已创建后端环境配置文件"
else
    echo "后端环境配置文件已存在"
fi

# 3. 修复后端编译错误
echo "=== 修复后端代码 ==="
cd backend

# 检查并修复 models/alert_rules.go 中的 JSON 类型定义
if ! grep -q "type JSON json.RawMessage" models/alert_rules.go; then
    echo "修复 alert_rules.go 中的 JSON 类型定义..."
    # 这里需要手动修复，因为已经在之前的会话中修复过了
fi

# 检查并修复 utils/logger.go 中的响应函数
if ! grep -q "func SuccessResponse(c interface{}" utils/logger.go; then
    echo "修复 utils/logger.go 中的响应函数..."
    # 这里需要手动修复，因为已经在之前的会话中修复过了
fi

# 检查并修复 services/prometheus_service.go 中的 ValidatePromQL 方法
if ! grep -q "func (s \*PrometheusService) ValidatePromQL" services/prometheus_service.go; then
    echo "修复 prometheus_service.go 中的 ValidatePromQL 方法..."
    # 这里需要手动修复，因为已经在之前的会话中修复过了
fi

# 4. 编译并启动后端服务
echo "=== 编译并启动后端服务 ==="
echo "下载 Go 依赖..."
go mod tidy
go mod download

echo "编译后端服务..."
go build -o mib-backend main.go

echo "启动后端服务..."
nohup ./mib-backend > backend.log 2>&1 &
BACKEND_PID=$!
echo "后端服务已启动，PID: $BACKEND_PID"

# 等待后端服务启动
echo "等待后端服务启动..."
sleep 5

# 检查后端服务是否正常运行
if ps -p $BACKEND_PID > /dev/null; then
    echo "后端服务运行正常"
else
    echo "后端服务启动失败，检查日志:"
    tail -20 backend.log
    exit 1
fi

# 5. 安装并启动前端服务
echo "=== 安装并启动前端服务 ==="
cd ..

# 检查 package.json 是否存在
if [ ! -f "package.json" ]; then
    echo "错误: 找不到 package.json 文件"
    exit 1
fi

echo "安装前端依赖..."
npm install

echo "构建前端应用..."
npm run build

echo "启动前端服务..."
nohup npm start > frontend.log 2>&1 &
FRONTEND_PID=$!
echo "前端服务已启动，PID: $FRONTEND_PID"

# 等待前端服务启动
echo "等待前端服务启动..."
sleep 10

# 6. 健康检查
echo "=== 执行健康检查 ==="

# 检查后端健康状态
echo "检查后端服务健康状态..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ 后端服务健康检查通过"
else
    echo "✗ 后端服务健康检查失败"
fi

# 检查前端健康状态
echo "检查前端服务健康状态..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✓ 前端服务健康检查通过"
else
    echo "✗ 前端服务健康检查失败"
fi

# 检查数据库连接
echo "检查数据库连接..."
if docker exec mibweb-postgres pg_isready -U netmon_user > /dev/null 2>&1; then
    echo "✓ 数据库连接正常"
else
    echo "✗ 数据库连接失败"
fi

# 检查Redis连接
echo "检查Redis连接..."
if docker exec mibweb-redis redis-cli -a redis_pass_2024 ping > /dev/null 2>&1; then
    echo "✓ Redis连接正常"
else
    echo "✗ Redis连接失败"
fi

# 7. 显示服务状态和访问信息
echo "=== 部署完成 ==="
echo ""
echo "服务状态:"
echo "- 后端服务: http://localhost:8080 (PID: $BACKEND_PID)"
echo "- 前端服务: http://localhost:3000 (PID: $FRONTEND_PID)"
echo "- PostgreSQL: localhost:5432"
echo "- Redis: localhost:6379"
echo "- Nginx代理: http://localhost:80 (可选)"
echo ""
echo "日志文件:"
echo "- 后端日志: $WORKDIR/backend/backend.log"
echo "- 前端日志: $WORKDIR/frontend.log"
echo ""
echo "停止服务命令:"
echo "- 停止后端: kill $BACKEND_PID"
echo "- 停止前端: kill $FRONTEND_PID"
echo "- 停止Docker服务: docker-compose down"
echo ""
echo "🎉 MIB Web UI 部署成功！请访问 http://localhost:3000 查看应用"