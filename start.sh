#!/bin/bash

# 快速启动脚本
echo "🚀 启动 SNMP Web UI..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请启动Docker"
    exit 1
fi

# 启动服务
echo "📦 启动Docker服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

echo "✅ 启动完成!"
echo "🌐 访问地址: http://localhost:3000"