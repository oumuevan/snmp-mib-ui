#!/bin/bash

# 停止脚本
echo "🛑 停止 SNMP Web UI..."

# 停止所有服务
docker-compose down

echo "✅ 服务已停止"