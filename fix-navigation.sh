#!/bin/bash

echo "🔧 修复导航栏和页面问题..."

# 重启开发服务器以应用更改
echo "♻️  重启开发服务器..."
pkill -f "next dev"
sleep 2

# 重新启动开发服务器
export NODE_ENV=development
export DATABASE_URL=postgresql://netmon_user:netmon_pass_2024@localhost:5432/network_monitor
export REDIS_URL=redis://:redis_pass_2024@localhost:6379
export NEXTAUTH_SECRET=mibweb_secret_key_2024_very_secure
export NEXTAUTH_URL=http://localhost:3000

echo "🚀 启动开发服务器..."
nohup npm run dev > dev-server.log 2>&1 &

echo "⏳ 等待服务器启动..."
sleep 10

echo "✅ 开发服务器已重启"
echo "🌐 访问地址: http://localhost:3000"

# 测试关键页面
echo "🧪 测试关键页面..."
echo "主页: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)"
echo "告警规则: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/alert-rules)"
echo "监控安装器: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/monitoring-installer)"

echo "🎉 修复完成！"